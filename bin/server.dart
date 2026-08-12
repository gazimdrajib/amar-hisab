import 'dart:async';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:amar_hisab/core/controllers/setup_controller.dart';
import 'package:amar_hisab/core/database/database_helper.dart';
import 'package:amar_hisab/core/events/domain_event.dart';
import 'package:amar_hisab/core/middleware/auth_middleware.dart';
import 'package:amar_hisab/core/middleware/rbac_middleware.dart';
import 'package:amar_hisab/core/seeders/role_seeder.dart';
import 'package:amar_hisab/core/services/audit_service.dart';
import 'package:amar_hisab/core/services/change_log_service.dart';
import 'package:amar_hisab/core/utils/response_envelope.dart';
import 'package:amar_hisab/core/utils/jwt_helper.dart';
import 'package:amar_hisab/modules/accounting/application/services/account_service.dart';
import 'package:amar_hisab/modules/accounting/application/services/journal_service.dart';
import 'package:amar_hisab/modules/accounting/application/services/ledger_service.dart';
import 'package:amar_hisab/modules/accounting/infrastructure/repositories/account_repository_impl.dart';
import 'package:amar_hisab/modules/accounting/infrastructure/repositories/journal_line_repository_impl.dart';
import 'package:amar_hisab/modules/accounting/infrastructure/repositories/journal_repository_impl.dart';
import 'package:amar_hisab/modules/accounting/presentation/controllers/account_controller.dart';
import 'package:amar_hisab/modules/accounting/presentation/controllers/journal_controller.dart';
import 'package:amar_hisab/modules/accounting/presentation/controllers/ledger_controller.dart';
import 'package:amar_hisab/modules/auth/application/services/auth_service.dart';
import 'package:amar_hisab/modules/auth/application/services/user_service.dart';
import 'package:amar_hisab/modules/auth/infrastructure/repositories/user_repository_impl.dart';
import 'package:amar_hisab/modules/auth/presentation/controllers/auth_controller.dart';
import 'package:amar_hisab/modules/auth/presentation/controllers/user_controller.dart';
import 'package:amar_hisab/modules/inventory/application/services/inventory_service.dart';
import 'package:amar_hisab/modules/inventory/application/services/warehouse_service.dart';
import 'package:amar_hisab/modules/inventory/infrastructure/repositories/batch_repository_impl.dart';
import 'package:amar_hisab/modules/inventory/infrastructure/repositories/stock_movement_repository_impl.dart';
import 'package:amar_hisab/modules/inventory/infrastructure/repositories/stock_repository_impl.dart';
import 'package:amar_hisab/modules/inventory/infrastructure/repositories/warehouse_repository_impl.dart';
import 'package:amar_hisab/modules/inventory/presentation/controllers/inventory_controller.dart';
import 'package:amar_hisab/modules/inventory/presentation/controllers/warehouse_controller.dart';
import 'package:amar_hisab/modules/products/application/services/brand_service.dart';
import 'package:amar_hisab/modules/products/application/services/category_service.dart';
import 'package:amar_hisab/modules/products/application/services/product_service.dart';
import 'package:amar_hisab/modules/products/application/services/unit_service.dart';
import 'package:amar_hisab/modules/products/infrastructure/repositories/brand_repository_impl.dart';
import 'package:amar_hisab/modules/products/infrastructure/repositories/category_repository_impl.dart';
import 'package:amar_hisab/modules/products/infrastructure/repositories/product_repository_impl.dart';
import 'package:amar_hisab/modules/products/infrastructure/repositories/unit_repository_impl.dart';
import 'package:amar_hisab/modules/products/presentation/controllers/brand_controller.dart';
import 'package:amar_hisab/modules/products/presentation/controllers/category_controller.dart';
import 'package:amar_hisab/modules/products/presentation/controllers/product_controller.dart';
import 'package:amar_hisab/modules/products/presentation/controllers/unit_controller.dart';
import 'package:amar_hisab/modules/purchases/application/services/purchase_service.dart';
import 'package:amar_hisab/modules/portal/application/services/portal_service.dart';
import 'package:amar_hisab/modules/portal/infrastructure/repositories/portal_repository.dart';
import 'package:amar_hisab/modules/portal/presentation/controllers/portal_controller.dart';
import 'package:amar_hisab/modules/reports/application/export/excel_export_provider.dart';
import 'package:amar_hisab/modules/reports/application/export/pdf_export_provider.dart';
import 'package:amar_hisab/modules/reports/application/services/report_export_service.dart';
import 'package:amar_hisab/modules/reports/application/services/report_service.dart';
import 'package:amar_hisab/modules/reports/presentation/controllers/report_controller.dart';
import 'package:amar_hisab/modules/purchases/infrastructure/repositories/purchase_item_repository_impl.dart';
import 'package:amar_hisab/modules/purchases/infrastructure/repositories/purchase_repository_impl.dart';
import 'package:amar_hisab/modules/purchases/infrastructure/repositories/supplier_payment_repository_impl.dart';
import 'package:amar_hisab/modules/purchases/presentation/controllers/purchases_controller.dart';
import 'package:amar_hisab/modules/sales/application/services/sales_service.dart';
import 'package:amar_hisab/modules/sales/infrastructure/repositories/sale_item_repository_impl.dart';
import 'package:amar_hisab/modules/sales/infrastructure/repositories/sale_payment_repository_impl.dart';
import 'package:amar_hisab/modules/sales/infrastructure/repositories/sale_repository_impl.dart';
import 'package:amar_hisab/modules/sales/infrastructure/repositories/sale_return_repository_impl.dart';
import 'package:amar_hisab/modules/sales/presentation/controllers/sales_controller.dart';
import 'package:amar_hisab/modules/sync/application/services/sync_engine.dart';
import 'package:amar_hisab/modules/sync/infrastructure/sync_client.dart';
import 'package:amar_hisab/modules/sync/presentation/controllers/sync_controller.dart';
import 'package:amar_hisab/monitoring/metrics.dart';

/// Global middleware: consistent JSON error handling + JSON content-type.
Middleware globalMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        MetricsRegistry.instance.inc('requests.total');
        return await innerHandler(request);
      } catch (error, stackTrace) {
        MetricsRegistry.instance.inc('errors.unhandled');
        stderr.writeln('Unhandled error: $error\n$stackTrace');
        return ResponseEnvelope.internalError();
      }
    };
  };
}

Future<void> main() async {
  final bootTime = DateTime.now().toUtc();

  // Load environment (.env file if present, then process env).
  final env = DotEnv(includePlatformEnvironment: true);
  env.load();

  // Bridge dotenv-loaded secrets into helpers that read Platform.environment
  // directly (Platform.environment itself is unmodifiable at runtime).
  final jwtSecret = env['JWT_SECRET'] ?? Platform.environment['JWT_SECRET'];
  if (jwtSecret != null && jwtSecret.isNotEmpty) {
    JwtHelper.initSecret(jwtSecret);
  }

  final host = env['HOST'] ?? Platform.environment['HOST'] ?? '0.0.0.0';
  final port =
      int.tryParse(env['PORT'] ?? Platform.environment['PORT'] ?? '') ?? 8080;

  if ((env['JWT_SECRET'] ?? Platform.environment['JWT_SECRET'] ?? '').isEmpty) {
    stderr.writeln(
        'WARNING: JWT_SECRET is not set. Set it in .env before accepting traffic.');
  }

  // ---------------- Database & migrations ----------------------------------
  final dbHelper = DatabaseHelper.instance;
  dbHelper.runMigrations();
  final db = dbHelper.db;

  // ---------------- Core services -------------------------------------------
  final auditService = AuditService(db);
  final changeLogService = ChangeLogService(db);
  final roleSeeder = RoleSeeder(db);
  final permissionChecker = PermissionChecker(db);

  // ---------------- Auth module (DI wiring) ---------------------------------
  final userRepository = UserRepositoryImpl(db);
  final authService = AuthService(userRepository);
  final userService = UserService(userRepository, auditService);
  final authController = AuthController(authService, permissionChecker);
  final userController = UserController(userService, permissionChecker);

  // ---------------- Products module -----------------------------------------
  final categoryRepository = CategoryRepositoryImpl(db);
  final brandRepository = BrandRepositoryImpl(db);
  final unitRepository = UnitRepositoryImpl(db);
  final productRepository = ProductRepositoryImpl(db);
  final categoryService = CategoryService(categoryRepository, auditService);
  final brandService = BrandService(brandRepository, auditService);
  final unitService = UnitService(unitRepository, auditService);
  final productService = ProductService(productRepository, auditService);
  final categoryController = CategoryController(categoryService, permissionChecker);
  final brandController = BrandController(brandService, permissionChecker);
  final unitController = UnitController(unitService, permissionChecker);
  final productController = ProductController(productService, permissionChecker);

  // ---------------- Events bus ---------------------------------------------
  final eventBus = LocalEventBus();

  // ---------------- Accounting module -----------------------------------------
  // Built before Inventory/Sales/Purchases so they can auto-post journals.
  final accountRepository = AccountRepositoryImpl(db);
  final journalLineRepository = JournalLineRepositoryImpl(db);
  final journalRepository =
      JournalRepositoryImpl(db, journalLineRepository);
  final accountService = AccountService(accountRepository, auditService);
  final journalService =
      JournalService(journalRepository, auditService, eventBus,
          changeLog: changeLogService);
  final ledgerService = LedgerService(db, journalLineRepository, auditService);
  final accountController = AccountController(accountService, permissionChecker);
  final journalController = JournalController(journalService, permissionChecker);
  final ledgerController = LedgerController(ledgerService, permissionChecker);

  /// Chart-of-accounts lookup used by Sales/Purchases/Inventory to auto-post.
  Future<int> accountLookup(int businessId, String accountName) async =>
      (await accountRepository.findByName(businessId, accountName))?.id ?? 0;

  // ---------------- Inventory module ----------------------------------------
  final warehouseRepository = WarehouseRepositoryImpl(db);
  final batchRepository = BatchRepositoryImpl(db);
  final stockRepository = StockRepositoryImpl(db);
  final movementRepository = StockMovementRepositoryImpl(db);
  final warehouseService = WarehouseService(warehouseRepository, auditService);
  final inventoryService = InventoryService(
      db, stockRepository, batchRepository, movementRepository, auditService,
      journalService: journalService, accountLookup: accountLookup,
      events: eventBus, changeLog: changeLogService);
  final warehouseController = WarehouseController(warehouseService, permissionChecker);
  final inventoryController = InventoryController(inventoryService, permissionChecker);

  // ---------------- Sales module --------------------------------------------
  final saleItemRepository = SaleItemRepositoryImpl(db);
  final salePaymentRepository = SalePaymentRepositoryImpl(db);
  final saleRepository =
      SaleRepositoryImpl(db, saleItemRepository, salePaymentRepository);
  final saleReturnRepository = SaleReturnRepositoryImpl(db);
  final salesService = SalesService(
      saleRepository, saleReturnRepository, inventoryService, auditService,
      eventBus,
      journalService: journalService, accountLookup: accountLookup,
      changeLog: changeLogService);
  final salesController = SalesController(salesService, permissionChecker);

  // ---------------- Purchases module -----------------------------------------
  final purchaseItemRepository = PurchaseItemRepositoryImpl(db);
  final supplierPaymentRepository = SupplierPaymentRepositoryImpl(db);
  final purchaseRepository =
      PurchaseRepositoryImpl(db, purchaseItemRepository, supplierPaymentRepository);
  final purchaseService = PurchaseService(
      purchaseRepository, inventoryService, auditService, eventBus,
      journalService: journalService, accountLookup: accountLookup,
      changeLog: changeLogService);
  final purchasesController =
      PurchasesController(purchaseService, permissionChecker);

  // ---------------- Reports module (Phase 8) --------------------------------
  // ReportService uses LedgerService for financial reports and queries the
  // sales/purchase/stock tables (written by SalesService / PurchaseService /
  // InventoryService) for transactional and stock reports.
  final reportService = ReportService(db, ledgerService, auditService);
  final reportExportService = ReportExportService(auditService, {
    const ExcelExportProvider().format: const ExcelExportProvider(),
    const PdfExportProvider().format: const PdfExportProvider(),
  });
  final reportController =
      ReportController(reportService, reportExportService, permissionChecker);

  // ---------------- Setup ----------------------------------------------------
  final setupController =
      SetupController(db, roleSeeder, auditService, permissionChecker);

  // ---------------- Sync module (Phase 9 Part C) -----------------------------
  final syncClient = SyncClient(
    deviceId: env['SYNC_DEVICE_ID'] ?? changeLogService.deviceId,
  );
  final syncEngine = SyncEngine(
    db: db,
    client: syncClient,
    changeLog: changeLogService,
    businessId: env['SYNC_BUSINESS_ID'],
  );
  if (syncEngine.isConfigured) {
    syncEngine.start();
    stdout.writeln('Cloud sync: enabled '
        '(device=${syncEngine.deviceId}, host=${syncClient.host})');
  } else {
    stdout.writeln('Cloud sync: disabled '
        '(set SYNC_ENABLED=true + SYNC_HOST to enable)');
  }
  final syncController = SyncController(syncEngine, permissionChecker);

  // ---------------- Portal module (Phase 9 Part F) ---------------------------
  final portalService =
      PortalService(PortalRepository(db), auditService, changeLogService);
  final portalController = PortalController(portalService);

  // ---------------- Daily batch-expiry checks (Event Catalog §3.3) ----------
  /// Publish [BatchExpiring] for every batch in its warning window once a day
  /// (the scan runs 24 hours after the server first starts and repeats).
  /// Uses the default single-tenant business id (the node currently hosts one
  /// business per local server – Architecture Book §6).
  final expiryTimer = Timer.periodic(const Duration(hours: 24), (_) async {
    try {
      final n = await inventoryService.publishExpiringBatches(1);
      if (n > 0) {
        stdout.writeln('BatchExpiring: published $n events for business 1');
      }
    } catch (e) {
      stderr.writeln('BatchExpiring check failed: $e');
    }
  });
  // Reference so the unused-variable lint stays silent (timer lives forever).
  unawaited(Future.sync(() => expiryTimer.tick));

  // ---------------- Routes ----------------------------------------------------
  final appRouter = Router();

  appRouter.get('/health', (Request request) {
    return ResponseEnvelope.success({
      'status': 'ok',
      'service': 'amar_hisab',
      'version': '1.0.0',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  });

  // Prometheus /metrics endpoint (metrics.dart – Architecture Book §11.7).
  appRouter.get('/metrics', (Request request) async {
    return metricsHandler(request, db, bootTime);
  });

  // OpenAPI spec + docs (swagger-ui via CDN; works offline enough for reads).
  appRouter.get('/api/docs', (Request request) {
    return Response.ok(
      '<!doctype html><html><head><meta charset="utf-8">'
      '<title>Amar Hisab API Docs</title>'
      '<link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">'
      '</head><body><div id="ui"></div>'
      '<script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>'
      '<script>window.onload=()=>{window.ui=SwaggerUIBundle({url:"/api/openapi.yaml",dom_id:"#ui"})};</script>'
      '</body></html>',
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  });
  appRouter.get('/api/openapi.yaml', (Request request) async {
    final candidates = [
      'api/openapi.yaml',
      '../api/openapi.yaml',
      '../../api/openapi.yaml',
    ];
    for (final path in candidates) {
      final file = File(path);
      if (await file.exists()) {
        return Response.ok(
          await file.readAsString(),
          headers: {'content-type': 'application/yaml; charset=utf-8'},
        );
      }
    }
    return ResponseEnvelope.notFound('api/openapi.yaml not found on disk');
  });

  // Public first-run setup.
  appRouter.mount('/setup/', setupController.router.call);

  // API v1 – auth & users.
  appRouter.mount('/api/v1/auth/', authController.router.call);
  appRouter.mount('/api/v1/users/', userController.router.call);

  // API v1 – products.
  appRouter.mount('/api/v1/categories/', categoryController.router.call);
  appRouter.mount('/api/v1/brands/', brandController.router.call);
  appRouter.mount('/api/v1/units/', unitController.router.call);
  appRouter.mount('/api/v1/products/', productController.router.call);

  // API v1 – inventory.
  appRouter.mount('/api/v1/warehouses/', warehouseController.router.call);
  appRouter.mount('/api/v1/inventory/', inventoryController.router.call);

  // API v1 – sales.
  appRouter.mount('/api/v1/sales/', salesController.router.call);

  // API v1 – purchases.
  appRouter.mount('/api/v1/purchases/', purchasesController.router.call);

  // API v1 – accounting (Architecture Book §15.6.4).
  appRouter.mount('/api/v1/accounting/accounts/', accountController.router.call);
  appRouter.mount('/api/v1/accounting/journal/', journalController.router.call);
  appRouter.mount('/api/v1/accounting/', ledgerController.router.call);

  // API v1 – reports (Phase 8).
  appRouter.mount('/api/v1/reports/', reportController.router.call);

  // API v1 – sync status & manual trigger (Phase 9).
  appRouter.mount('/api/v1/sync/', syncController.router.call);

  // Public portal & QR self-service (Proto Contract Book §3.8).
  appRouter.mount('/public/portal/', portalController.portalRouter.call);
  appRouter.mount('/public/qr/', portalController.qrRouter.call);

  appRouter.all('/<ignored|.*>', (Request request) {
    return ResponseEnvelope.notFound('Route not found: ${request.url.path}');
  });

  // ---------------- Pipeline --------------------------------------------------
  final handler = const Pipeline()
      .addMiddleware(globalMiddleware())
      .addMiddleware(authMiddleware())
      .addHandler(appRouter.call);

  final server = await shelf_io.serve(handler, host, port);
  server.autoCompress = true;

  // Handle graceful shutdown.
  ProcessSignal.sigint.watch().listen((_) async {
    stdout.writeln('Shutting down…');
    await syncEngine.dispose();
    await syncClient.dispose();
    dbHelper.close();
    await server.close(force: true);
    exit(0);
  });

  stdout.writeln(
      'Amar Hisab v1.0.0 listening on ${server.address.host}:${server.port}');
  stdout.writeln('Health: http://${server.address.host}:${server.port}/health');
}
