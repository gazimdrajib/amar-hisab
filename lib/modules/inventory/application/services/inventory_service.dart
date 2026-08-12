import 'package:sqlite3/sqlite3.dart';

import '../../../../core/events/domain_event.dart';
import '../../../../core/events/domain_events.dart';
import '../../../../core/services/audit_service.dart';
import '../../../../core/services/change_log_service.dart';
import '../../../accounting/application/services/journal_service.dart';
import '../../../accounting/domain/entities/journal_line.dart';
import '../../domain/entities/batch.dart';
import '../../domain/entities/stock.dart';
import '../../domain/entities/stock_movement.dart';
import '../../domain/repositories/batch_repository.dart';
import '../../domain/repositories/stock_movement_repository.dart';
import '../../domain/repositories/stock_repository.dart';
import 'warehouse_service.dart' show InventoryServiceException;

/// FIFO-based stock operations. Every public mutation:
///
///  1. Opens a SQLite **transaction** (`BEGIN IMMEDIATE … COMMIT/ROLLBACK`)
///     so partial changes never persist.
///  2. Writes one or more `stock_movements` ledger rows through the
///     [StockMovementRepository].
///  3. Maintains the denormalised `stock` aggregate through
///     [StockRepository.upsertAdd] (delta arithmetic).
///  4. Appends an `audit_log` row via [AuditService].
///  5. Records the mutation in the transactional outbox (`change_log`) via
///     [ChangeLogService] **inside** the same transaction.
///  6. After commit, publishes [StockLow] when a threshold was crossed
///     (Event Catalog §3.3).
class InventoryService {
  InventoryService(
    this._db,
    this._stockRepo,
    this._batchRepo,
    this._movementRepo,
    this._audit, {
    JournalService? journalService,
    AccountLookup? accountLookup,
    EventBus? events,
    ChangeLogService? changeLog,
  })  : _journalService = journalService,
        _accountLookup = accountLookup,
        _events = events,
        _changeLog = changeLog;

  final Database _db;
  final StockRepository _stockRepo;
  final BatchRepository _batchRepo;
  final StockMovementRepository _movementRepo;
  final AuditService _audit;
  final JournalService? _journalService;
  final AccountLookup? _accountLookup;
  final EventBus? _events;
  final ChangeLogService? _changeLog;

  // -- Queries ----------------------------------------------------------------

  Future<List<Stock>> stockForProduct(int businessId, int productId) =>
      _stockRepo.findByProduct(businessId, productId);

  Future<List<Stock>> stockForWarehouse(int businessId, int warehouseId) =>
      _stockRepo.findByWarehouse(businessId, warehouseId);

  Future<List<StockMovement>> productHistory(int businessId, int productId,
          {int limit = 200}) =>
      _movementRepo.findByProduct(businessId, productId, limit: limit);

  Future<List<Batch>> batchesFor(int businessId, int productId,
          {int? warehouseId}) =>
      _batchRepo.findByProduct(businessId, productId, warehouseId: warehouseId);

  // -- Mutations --------------------------------------------------------------

  /// Add [quantity] units of [productId] into [warehouseId], recording a new
  /// batch when [batchNumber]/expiry info is provided.
  Future<Stock> addStock({
    required int businessId,
    required int productId,
    required int warehouseId,
    required double quantity,
    String? batchNumber,
    double purchasePrice = 0,
    DateTime? expiryDate,
    int? batchId,
    String? referenceType,
    int? referenceId,
    String? note,
    required int actorId,
  }) async {
    _requirePositive(quantity, 'quantity');
    int? resolvedBatchId = batchId;
    late Stock result;

    await _inTransaction(() async {
      // Create / reference the batch inside the same transaction.
      if (resolvedBatchId == null) {
        final batch = await _batchRepo.insert(Batch(
          businessId: businessId,
          productId: productId,
          warehouseId: warehouseId,
          batchNumber: batchNumber ?? 'AUTO-${DateTime.now().millisecondsSinceEpoch}',
          purchasePrice: purchasePrice,
          expiryDate: expiryDate,
          receivedAt: DateTime.now(),
          quantity: quantity,
        ));
        resolvedBatchId = batch.id!;
      } else {
        final batch = await _batchRepo.findById(resolvedBatchId!);
        if (batch == null) {
          throw InventoryServiceException('batch_not_found', 'Batch not found');
        }
        await _batchRepo.adjustQuantity(batch.id!, batch.quantity + quantity);
      }

      await _stockRepo.upsertAdd(businessId, productId, warehouseId, quantity);
      final movement = await _movementRepo.insert(StockMovement(
        businessId: businessId,
        productId: productId,
        warehouseId: warehouseId,
        batchId: resolvedBatchId,
        movementType: 'add',
        quantity: quantity,
        referenceType: referenceType,
        referenceId: referenceId,
        note: note,
        performedBy: actorId,
      ));
      _recordMovement(movement, businessId);
      _audit.logAction(
        userId: actorId,
        entityType: 'stock_movement',
        entityId: productId,
        action: 'addStock',
        newValue: '+$quantity @ warehouse $warehouseId',
        businessId: businessId,
      );
      result = (await _stockRepo.find(businessId, productId, warehouseId))!;
    });

    return result;
  }

  /// Deduct [quantity] from the available stock of [productId] in
  /// [warehouseId], consuming FIFO batches (oldest `received_at` first).
  Future<Stock> deductStock({
    required int businessId,
    required int productId,
    required int warehouseId,
    required double quantity,
    String movementType = 'deduct',
    String? referenceType,
    int? referenceId,
    String? note,
    required int actorId,
  }) async {
    _requirePositive(quantity, 'quantity');
    late Stock result;

    await _inTransaction(() async {
      final current = await _stockRepo.find(businessId, productId, warehouseId);
      final available = current?.quantity ?? 0;
      if (available < quantity) {
        throw InventoryServiceException(
          'insufficient_stock',
          'Insufficient stock (available: $available, requested: $quantity)',
        );
      }

      // FIFO consumption across batches.
      var remaining = quantity;
      final batches =
          await _batchRepo.findFifoBatches(businessId, productId, warehouseId);
      for (final batch in batches) {
        if (remaining <= 0) break;
        final take = batch.quantity > remaining ? remaining : batch.quantity;
        await _batchRepo.adjustQuantity(batch.id!, batch.quantity - take);
        final movement = await _movementRepo.insert(StockMovement(
          businessId: businessId,
          productId: productId,
          warehouseId: warehouseId,
          batchId: batch.id,
          movementType: movementType,
          quantity: -take,
          referenceType: referenceType,
          referenceId: referenceId,
          note: note,
          performedBy: actorId,
        ));
        _recordMovement(movement, businessId);
        remaining -= take;
      }

      await _stockRepo.upsertAdd(businessId, productId, warehouseId, -quantity);
      _audit.logAction(
        userId: actorId,
        entityType: 'stock_movement',
        entityId: productId,
        action: 'deductStock',
        newValue: '-$quantity @ warehouse $warehouseId ($movementType)',
        businessId: businessId,
      );
      result = (await _stockRepo.find(businessId, productId, warehouseId))!;
      _recordStockSnapshot(businessId, productId, warehouseId, result.quantity);
    });

    // Event Catalog §3.3: low-stock check happens AFTER the stock transaction
    // commits (purely local alert – no sync event).
    await _checkLowStock(businessId, productId, warehouseId, result.quantity);
    return result;
  }

  /// Move [quantity] of [productId] from one warehouse to another within the
  /// same business. Consumes source FIFO batches and creates a matched batch
  /// at the destination.
  Future<void> transferStock({
    required int businessId,
    required int productId,
    required int fromWarehouseId,
    required int toWarehouseId,
    required double quantity,
    String? note,
    required int actorId,
  }) async {
    _requirePositive(quantity, 'quantity');
    if (fromWarehouseId == toWarehouseId) {
      throw InventoryServiceException(
          'same_warehouse', 'Source and destination warehouses are identical');
    }

    await _inTransaction(() async {
      final source = await _stockRepo.find(businessId, productId, fromWarehouseId);
      if ((source?.quantity ?? 0) < quantity) {
        throw InventoryServiceException(
            'insufficient_stock', 'Insufficient stock at source warehouse');
      }

      // Deduct from source (FIFO batches consumed).
      var remaining = quantity;
      final sourceBatches = await _batchRepo.findFifoBatches(
          businessId, productId, fromWarehouseId);
      final destinations = <Map<String, Object?>>[];
      for (final batch in sourceBatches) {
        if (remaining <= 0) break;
        final take = batch.quantity > remaining ? remaining : batch.quantity;
        await _batchRepo.adjustQuantity(batch.id!, batch.quantity - take);
        destinations.add({
          'qty': take,
          'price': batch.purchasePrice,
          'expiry': batch.expiryDate?.toIso8601String(),
          'batchNumber': batch.batchNumber,
        });
        final outMovement = await _movementRepo.insert(StockMovement(
          businessId: businessId,
          productId: productId,
          warehouseId: fromWarehouseId,
          batchId: batch.id,
          movementType: 'transfer_out',
          quantity: -take,
          referenceType: 'warehouse',
          referenceId: toWarehouseId,
          note: note,
          performedBy: actorId,
        ));
        _recordMovement(outMovement, businessId);
        remaining -= take;
      }
      await _stockRepo.upsertAdd(businessId, productId, fromWarehouseId, -quantity);

      // Add to destination – recreate batches mirroring FIFO order.
      for (final d in destinations) {
        final batch = await _batchRepo.insert(Batch(
          businessId: businessId,
          productId: productId,
          warehouseId: toWarehouseId,
          batchNumber: '${d['batchNumber']}-T',
          purchasePrice: (d['price'] as num?)?.toDouble() ?? 0,
          expiryDate: d['expiry'] == null
              ? null
              : DateTime.tryParse(d['expiry']! as String),
          receivedAt: DateTime.now(),
          quantity: (d['qty'] as num).toDouble(),
        ));
        final inMovement = await _movementRepo.insert(StockMovement(
          businessId: businessId,
          productId: productId,
          warehouseId: toWarehouseId,
          batchId: batch.id,
          movementType: 'transfer_in',
          quantity: (d['qty'] as num).toDouble(),
          referenceType: 'warehouse',
          referenceId: fromWarehouseId,
          note: note,
          performedBy: actorId,
        ));
        _recordMovement(inMovement, businessId);
      }
      await _stockRepo.upsertAdd(businessId, productId, toWarehouseId, quantity);

      _audit.logAction(
        userId: actorId,
        entityType: 'stock_movement',
        entityId: productId,
        action: 'transferStock',
        newValue: '$quantity from warehouse $fromWarehouseId to $toWarehouseId',
        businessId: businessId,
      );
    });
  }

  /// Correct the stock level for [productId] in [warehouseId] to
  /// [newQuantity]. The difference is written as an `adjust` movement.
  Future<Stock> adjustStock({
    required int businessId,
    required int productId,
    required int warehouseId,
    required double newQuantity,
    String? note,
    required int actorId,
  }) async {
    if (newQuantity < 0) {
      throw InventoryServiceException(
          'invalid_quantity', 'New quantity cannot be negative');
    }

    late Stock result;
    var old = 0.0;
    var delta = 0.0;
    await _inTransaction(() async {
      final current = await _stockRepo.find(businessId, productId, warehouseId);
      old = current?.quantity ?? 0;
      delta = newQuantity - old;
      if (delta == 0) return;

      if (delta < 0) {
        // Consume batches FIFO for negative corrections.
        var remaining = -delta;
        final batches = await _batchRepo.findFifoBatches(
            businessId, productId, warehouseId);
        for (final batch in batches) {
          if (remaining <= 0) break;
          final take = batch.quantity > remaining ? remaining : batch.quantity;
          await _batchRepo.adjustQuantity(batch.id!, batch.quantity - take);
          remaining -= take;
        }
      }
      await _stockRepo.upsertAdd(businessId, productId, warehouseId, delta);
      final adjustMovement = await _movementRepo.insert(StockMovement(
        businessId: businessId,
        productId: productId,
        warehouseId: warehouseId,
        movementType: 'adjust',
        quantity: delta,
        note: note,
        performedBy: actorId,
      ));
      _recordMovement(adjustMovement, businessId);
      _audit.logAction(
        userId: actorId,
        entityType: 'stock_movement',
        entityId: productId,
        action: 'adjustStock',
        oldValue: old.toString(),
        newValue: newQuantity.toString(),
        businessId: businessId,
      );
      result = (await _stockRepo.find(businessId, productId, warehouseId))!;
    });

    // Accounting auto-posting (Architecture Book §13.5): writes an inventory
    // adjustment journal once the stock transaction has committed.
    await _postAdjustment(
        businessId, productId, old, newQuantity, delta, note, actorId);

    return result;
  }

  // -- Helpers ---------------------------------------------------------------

  /// Auto-post an inventory adjustment journal:
  ///   delta > 0 → DR Inventory, CR Inventory Adjustment
  ///   delta < 0 → DR Inventory Adjustment, CR Inventory
  ///
  /// The adjustment amount uses the product's latest purchase price as the
  /// valuation basis. Silently skips when accounts cannot be resolved.
  Future<void> _postAdjustment(
    int businessId,
    int productId,
    double oldQuantity,
    double newQuantity,
    double delta,
    String? note,
    int actorId,
  ) async {
    final journalService = _journalService;
    final lookup = _accountLookup;
    if (journalService == null || lookup == null || delta == 0) return;

    // Valuation: use the most recent batch purchase price for the product.
    double unit = 0;
    try {
      final rows = _db.select(
        'SELECT purchase_price FROM batches '
        'WHERE business_id = ? AND product_id = ? '
        'ORDER BY id DESC LIMIT 1;',
        [businessId, productId],
      );
      if (rows.isNotEmpty) {
        unit = (rows.first['purchase_price'] as num?)?.toDouble() ?? 0;
      }
    } catch (_) {
      // best-effort valuation; skip posting when we cannot value the delta
    }
    final amount = (delta * unit).abs();
    if (amount <= 0.0001) return;

    final inventory = await lookup(businessId, 'Inventory');
    final adjustment =
        await lookup(businessId, 'Inventory Adjustment');
    if (inventory == 0 || adjustment == 0) return;

    final ref = 'ADJ-$productId-${DateTime.now().microsecondsSinceEpoch}';
    final desc = note ?? 'Stock adjustment for product #$productId';
    final lines = <JournalLine>[
      if (delta > 0) ...[
        JournalLine(
            accountId: inventory, debit: amount, description: desc),
        JournalLine(
            accountId: adjustment, credit: amount, description: desc),
      ] else ...[
        JournalLine(
            accountId: adjustment, debit: amount, description: desc),
        JournalLine(
            accountId: inventory, credit: amount, description: desc),
      ],
    ];

    await journalService.createAndPost(
      businessId: businessId,
      entryDate: DateTime.now(),
      reference: ref,
      note: 'Auto-posted stock adjustment (old=$oldQuantity new=$newQuantity)',
      lines: lines,
      actorId: actorId,
    );
  }

  int _txDepth = 0;

  /// Append the movement to the transactional outbox (Event Catalog §4.2 –
  /// `stock_movement` INSERT). Runs inside the caller's transaction.
  void _recordMovement(StockMovement movement, int businessId) {
    _changeLog?.recordChange(
      entityType: 'stock_movement',
      entityId: movement.id ?? 0,
      operation: ChangeOperation.insert,
      payload: {
        'id': movement.id,
        'business_id': movement.businessId,
        'product_id': movement.productId,
        'warehouse_id': movement.warehouseId,
        'batch_id': movement.batchId,
        'movement_type': movement.movementType,
        'quantity': movement.quantity,
        'reference_type': movement.referenceType,
        'reference_id': movement.referenceId,
        'note': movement.note,
        'performed_by': movement.performedBy,
      },
      businessId: businessId,
    );
  }

  /// Snapshot of the `stock` aggregate row for peers still on the v1 schema
  /// (event-sourced peers ignore the quantity column — Part E).
  void _recordStockSnapshot(
      int businessId, int productId, int warehouseId, double quantity) {
    _changeLog?.recordChange(
      entityType: 'stock',
      entityId: productId,
      operation: ChangeOperation.update,
      payload: {
        'product_id': productId,
        'warehouse_id': warehouseId,
        'quantity': quantity,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      businessId: businessId,
    );
  }

  /// Publish [StockLow] when the aggregate drops to/below the product's
  /// `min_stock_level` (Event Catalog §3.3). Runs AFTER commit; failures are
  /// swallowed so alert delivery never rolls back the sale/purchase.
  Future<void> _checkLowStock(int businessId, int productId, int warehouseId,
      double currentQuantity) async {
    final events = _events;
    if (events == null) return;
    try {
      final rows = _db.select(
        'SELECT min_stock_level FROM products '
        'WHERE id = ? AND business_id = ? LIMIT 1;',
        [productId, businessId],
      );
      if (rows.isEmpty) return;
      final threshold =
          (rows.first['min_stock_level'] as num?)?.toDouble() ?? 0;
      if (threshold > 0 && currentQuantity <= threshold) {
        events.publish(StockLow(
          productId: productId,
          warehouseId: warehouseId,
          currentQuantity: currentQuantity,
          threshold: threshold,
          businessId: businessId,
        ));
      }
    } catch (_) {
      // Best-effort alerting only.
    }
  }

  /// Scheduled expiry check (Event Catalog §3.3 – [BatchExpiring]). Called by
  /// the daily background task in `bin/server.dart`; publishes one event per
  /// batch expiring within [warningDays].
  Future<int> publishExpiringBatches(int businessId,
      {int warningDays = 30}) async {
    final events = _events;
    if (events == null) return 0;
    final cutoff = DateTime.now().toUtc().add(Duration(days: warningDays));
    final rows = _db.select(
      'SELECT b.id AS batch_id, b.product_id, b.expiry_date, b.quantity, '
      '       b.batch_number, p.name AS product_name '
      'FROM batches b '
      'JOIN products p ON p.id = b.product_id '
      'WHERE b.business_id = ? AND b.is_active = 1 AND b.quantity > 0 '
      '  AND b.expiry_date IS NOT NULL AND b.expiry_date <= ?;',
      [businessId, cutoff.toIso8601String()],
    );
    var published = 0;
    for (final row in rows) {
      final expiry = DateTime.tryParse(row['expiry_date'] as String? ?? '');
      if (expiry == null) continue;
      final daysLeft = expiry.difference(DateTime.now().toUtc()).inDays;
      events.publish(BatchExpiring(
        batchId: row['batch_id'] as int,
        productId: row['product_id'] as int,
        productName: row['product_name'] as String?,
        batchNumber: row['batch_number'] as String?,
        expiryDate: expiry,
        daysLeft: daysLeft,
        currentQuantity: (row['quantity'] as num?)?.toDouble(),
        businessId: businessId,
      ));
      published++;
    }
    return published;
  }

  /// Run [fn] inside this service's transaction context. Nested calls share
  /// the outer transaction (no nested `BEGIN`), so cross-module services
  /// (e.g. SalesService) can compose stock mutations atomically with their
  /// own persistence.
  Future<void> runInTransaction(Future<void> Function() fn) =>
      _inTransaction(fn);

  void _requirePositive(double value, String field) {
    if (value <= 0) {
      throw InventoryServiceException(
          'invalid_quantity', '$field must be greater than zero');
    }
  }

  /// Run [fn] inside a transaction, automatically committing or rolling
  /// back on error.
  ///
  /// sqlite3 executes each statement synchronously, but the closure is async
  /// (it awaits Futures from repositories/services). The wrapper therefore
  /// `await`s [fn], so every statement inside the closure completes — and all
  /// of its SQL lands between `BEGIN` and `COMMIT`/`ROLLBACK` — before the
  /// wrapper decides to commit. Concurrent requests aiming for the same
  /// transaction are serialised by SQLite's `BEGIN IMMEDIATE` lock.
  Future<void> _inTransaction(Future<void> Function() fn) async {
    final isOuter = _txDepth == 0;
    if (isOuter) {
      _db.execute('BEGIN IMMEDIATE;');
    }
    _txDepth++;
    try {
      await fn();
    } catch (error, stackTrace) {
      if (isOuter) {
        _db.execute('ROLLBACK;');
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _txDepth--;
    }
    if (isOuter) {
      _db.execute('COMMIT;');
    }
  }
}
