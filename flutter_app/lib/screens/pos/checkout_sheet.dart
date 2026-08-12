import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../models/cart.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../widgets/common.dart';

/// Bottom sheet collecting payment and submitting POST /api/v1/sales/.
class CheckoutSheet extends ConsumerStatefulWidget {
  final int warehouseId;
  const CheckoutSheet({super.key, required this.warehouseId});

  @override
  ConsumerState<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends ConsumerState<CheckoutSheet> {
  PaymentMethod _method = PaymentMethod.cash;
  final _tenderedCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _tenderedCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final cart = ref.read(cartProvider);
    final tendered = double.tryParse(_tenderedCtrl.text) ?? 0;

    final paidAmount = _method == PaymentMethod.credit
        ? 0.0
        : (tendered > cart.grandTotal ? cart.grandTotal : tendered);

    final payload = ref.read(cartProvider.notifier).toSalePayload(
      warehouseId: widget.warehouseId,
      paidAmount: _method == PaymentMethod.credit ? 0 : paidAmount,
      paymentMethod: _method == PaymentMethod.credit
          ? 'Cash'
          : _method.label.split(' ').first,
      note: _noteCtrl.text,
    );

    try {
      final detail = await ref
          .read(checkoutControllerProvider.notifier)
          .checkout(payload);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Sale completed'),
          content: Text(
              'Invoice ${detail.invoiceNumber}\nTotal: ${Fmt.money(detail.grandTotal)}\nDue: ${Fmt.money(detail.dueAmount)}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, isError: true);
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final checkout = ref.watch(checkoutControllerProvider);
    final tendered = double.tryParse(_tenderedCtrl.text) ?? 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Payment', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Total: ${Fmt.money(cart.grandTotal)}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: PaymentMethod.values
                  .map((m) => ChoiceChip(
                        label: Text(m.label),
                        selected: _method == m,
                        onSelected: (_) => setState(() {
                          _method = m;
                          if (m == PaymentMethod.credit) {
                            _tenderedCtrl.text = '0';
                          } else if (_tenderedCtrl.text.isEmpty ||
                              _tenderedCtrl.text == '0') {
                            _tenderedCtrl.text =
                                cart.grandTotal.toStringAsFixed(0);
                          }
                        }),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            if (_method != PaymentMethod.credit) ...[
              TextField(
                controller: _tenderedCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount received',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              if (tendered > cart.grandTotal)
                Text('Change due: ${Fmt.money(tendered - cart.grandTotal)}',
                    style: TextStyle(color: Colors.green.shade700)),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                    'This sale will be recorded as fully due (credit / বাকিতে).'),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700),
                onPressed: checkout.isLoading ? null : _confirm,
                icon: checkout.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(
                    checkout.isLoading ? 'Processing…' : 'Confirm Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
