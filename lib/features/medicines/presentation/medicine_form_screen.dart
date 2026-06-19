import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../domain/medicine.dart';
import 'medicine_providers.dart';

/// Create / edit form for a [Medicine]. Pass [existing] to edit.
class MedicineFormScreen extends ConsumerStatefulWidget {
  const MedicineFormScreen({super.key, this.existing});

  final Medicine? existing;

  @override
  ConsumerState<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends ConsumerState<MedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _batch;
  late final TextEditingController _manufacturer;
  late final TextEditingController _quantity;
  late final TextEditingController _reorder;
  late final TextEditingController _purchase;
  late final TextEditingController _selling;

  late String _category;
  late DateTime _mfgDate;
  late DateTime _expiryDate;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final m = widget.existing;
    _name = TextEditingController(text: m?.name ?? '');
    _batch = TextEditingController(text: m?.batchNumber ?? '');
    _manufacturer = TextEditingController(text: m?.manufacturer ?? '');
    _quantity = TextEditingController(text: m?.quantity.toString() ?? '');
    _reorder = TextEditingController(
        text: m?.reorderLevel.toString() ??
            AppConstants.defaultReorderLevel.toString());
    _purchase = TextEditingController(
        text: m?.purchasePrice.toStringAsFixed(2) ?? '');
    _selling =
        TextEditingController(text: m?.sellingPrice.toStringAsFixed(2) ?? '');
    _category = m?.category ?? AppConstants.medicineCategories.first;
    _mfgDate = m?.manufacturingDate ??
        DateTime.now().subtract(const Duration(days: 30));
    _expiryDate =
        m?.expiryDate ?? DateTime.now().add(const Duration(days: 365));
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _batch,
      _manufacturer,
      _quantity,
      _reorder,
      _purchase,
      _selling
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool isExpiry}) async {
    final initial = isExpiry ? _expiryDate : _mfgDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
        } else {
          _mfgDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate.isBefore(_mfgDate)) {
      _toast('Expiry date must be after the manufacturing date.');
      return;
    }
    setState(() => _saving = true);

    final quantity = int.parse(_quantity.text.trim());
    final now = DateTime.now();
    final notifier = ref.read(medicinesProvider.notifier);

    try {
      if (_isEditing) {
        final updated = widget.existing!.copyWith(
          name: _name.text.trim(),
          category: _category,
          batchNumber: _batch.text.trim(),
          manufacturer: _manufacturer.text.trim(),
          quantity: quantity,
          // keep the higher of original baseline and current qty for a sane %.
          initialQuantity: quantity > widget.existing!.initialQuantity
              ? quantity
              : widget.existing!.initialQuantity,
          reorderLevel: int.parse(_reorder.text.trim()),
          purchasePrice: double.parse(_purchase.text.trim()),
          sellingPrice: double.parse(_selling.text.trim()),
          manufacturingDate: _mfgDate,
          expiryDate: _expiryDate,
        );
        await notifier.edit(updated);
      } else {
        final medicine = Medicine(
          id: AppDatabase.newId(),
          name: _name.text.trim(),
          category: _category,
          batchNumber: _batch.text.trim(),
          manufacturer: _manufacturer.text.trim(),
          quantity: quantity,
          initialQuantity: quantity,
          reorderLevel: int.parse(_reorder.text.trim()),
          purchasePrice: double.parse(_purchase.text.trim()),
          sellingPrice: double.parse(_selling.text.trim()),
          manufacturingDate: _mfgDate,
          expiryDate: _expiryDate,
          createdAt: now,
          updatedAt: now,
        );
        await notifier.add(medicine);
      }
      if (mounted) {
        Navigator.of(context).pop();
        _toast(_isEditing ? 'Medicine updated.' : 'Medicine registered.');
      }
    } catch (e) {
      if (mounted) _toast('Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medicine' : 'Register Medicine'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _field(_name, 'Medicine name', icon: Icons.medication_outlined,
                validator: _required),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: AppConstants.medicineCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 14),
            _field(_batch, 'Batch number', icon: Icons.tag, validator: _required),
            const SizedBox(height: 14),
            _field(_manufacturer, 'Manufacturer',
                icon: Icons.factory_outlined, validator: _required),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _field(_quantity, 'Quantity',
                      icon: Icons.inventory_2_outlined,
                      keyboard: TextInputType.number,
                      digitsOnly: true,
                      validator: _positiveInt),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_reorder, 'Reorder level',
                      icon: Icons.low_priority,
                      keyboard: TextInputType.number,
                      digitsOnly: true,
                      validator: _positiveInt),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _field(_purchase, 'Purchase price',
                      icon: Icons.shopping_cart_outlined,
                      keyboard:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: _price),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(_selling, 'Selling price',
                      icon: Icons.sell_outlined,
                      keyboard:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: _price),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _dateField(
                      'Manufacturing date', _mfgDate, () => _pickDate(isExpiry: false)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateField(
                      'Expiry date', _expiryDate, () => _pickDate(isExpiry: true)),
                ),
              ],
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Icon(Icons.save_outlined),
              label: Text(_isEditing ? 'Save changes' : 'Register medicine'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    required IconData icon,
    TextInputType? keyboard,
    bool digitsOnly = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: digitsOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : (keyboard != null
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : null),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
    );
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(Formatters.date(value)),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _positiveInt(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = int.tryParse(v.trim());
    if (n == null || n < 0) return 'Invalid';
    return null;
  }

  String? _price(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null || n < 0) return 'Invalid';
    return null;
  }
}
