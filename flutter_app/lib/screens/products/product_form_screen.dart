import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../models/product.dart';
import '../../providers/catalog_providers.dart';
import '../../widgets/common.dart';

/// Create / edit form for a Product.
class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, this.product});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _sku = TextEditingController(text: widget.product?.sku ?? '');
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _barcode =
      TextEditingController(text: widget.product?.barcode ?? '');
  late final _description =
      TextEditingController(text: widget.product?.description ?? '');
  late final _purchasePrice = TextEditingController(
      text: widget.product == null ? '' : '${widget.product!.purchasePrice}');
  late final _sellingPrice = TextEditingController(
      text: widget.product == null ? '' : '${widget.product!.sellingPrice}');
  late final _taxRate = TextEditingController(
      text: widget.product == null ? '' : '${widget.product!.taxRate}');
  late final _minStock = TextEditingController(
      text: widget.product == null ? '' : '${widget.product!.minStockLevel}');
  int? _categoryId;
  int? _brandId;
  int? _unitId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.product?.categoryId;
    _brandId = widget.product?.brandId;
    _unitId = widget.product?.unitId;
  }

  @override
  void dispose() {
    for (final c in [
      _sku,
      _name,
      _barcode,
      _description,
      _purchasePrice,
      _sellingPrice,
      _taxRate,
      _minStock,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'sku': _sku.text.trim(),
      'name': _name.text.trim(),
      if (_barcode.text.trim().isNotEmpty) 'barcode': _barcode.text.trim(),
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
      if (_categoryId != null) 'categoryId': _categoryId,
      if (_brandId != null) 'brandId': _brandId,
      if (_unitId != null) 'unitId': _unitId,
      'purchasePrice': double.tryParse(_purchasePrice.text) ?? 0,
      'sellingPrice': double.tryParse(_sellingPrice.text) ?? 0,
      'taxRate': double.tryParse(_taxRate.text) ?? 0,
      'minStockLevel': double.tryParse(_minStock.text) ?? 0,
    };
    try {
      final notifier = ref.read(productListProvider.notifier);
      if (widget.product == null) {
        await notifier.create(payload);
      } else {
        await notifier.edit(widget.product!.id, payload);
      }
      if (mounted) {
        showSnack(context, 'Product saved');
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoryListProvider).value ?? [];
    final brands = ref.watch(brandListProvider).value ?? [];
    final units = ref.watch(unitListProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.product == null ? 'New Product' : 'Edit Product')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _sku,
                  decoration: const InputDecoration(
                      labelText: 'SKU *', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _barcode,
                  decoration: const InputDecoration(
                      labelText: 'Barcode', border: OutlineInputBorder()),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Product name *', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration: const InputDecoration(
                      labelText: 'Category', border: OutlineInputBorder()),
                  items: categories
                      .map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _brandId,
                  decoration: const InputDecoration(
                      labelText: 'Brand', border: OutlineInputBorder()),
                  items: brands
                      .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _brandId = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _unitId,
                  decoration: const InputDecoration(
                      labelText: 'Unit', border: OutlineInputBorder()),
                  items: units
                      .map((u) => DropdownMenuItem(
                          value: u.id,
                          child: Text('${u.name} (${u.abbreviation})')))
                      .toList(),
                  onChanged: (v) => setState(() => _unitId = v),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _numberField(
                    _purchasePrice, 'Purchase price', requiredField: false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                    _sellingPrice, 'Selling price', requiredField: false),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _numberField(_taxRate, 'VAT rate %')),
              const SizedBox(width: 12),
              Expanded(child: _numberField(_minStock, 'Min stock level')),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save Product'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController ctrl, String label,
          {bool requiredField = false}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration:
            InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: requiredField
            ? (v) =>
                double.tryParse(v ?? '') == null ? 'Enter a number' : null
            : null,
      );
}
