import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/input_parsing.dart';
import '../../../state/retail_providers.dart';
import '../../../state/retail_snapshot.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/retailer/product_option.dart';
import '../../../widgets/shared/number_field.dart';
import '../../../widgets/shared/searchable_dropdown.dart';
import '../../../widgets/shared/searchable_option.dart';
import '../../../invoices/round_money.dart';
import '../../../widgets/shared/total_banner.dart';

/// New stock in. The app makes the batch_id; the retailer only picks
/// product and vendor from dropdowns and types a number.
class AddStockScreen extends ConsumerStatefulWidget {
  const AddStockScreen({super.key});

  @override
  ConsumerState<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends ConsumerState<AddStockScreen> {
  String? _sku;
  String? _vendor_id;
  final _qty_controller = TextEditingController();
  final _cost_controller = TextEditingController();
  bool _is_saving = false;

  @override
  void dispose() {
    _qty_controller.dispose();
    _cost_controller.dispose();
    super.dispose();
  }

  List<SearchableOption<String>> _vendor_options(RetailSnapshot snapshot) => [
        for (final vendor in snapshot.vendors)
          SearchableOption<String>(value: vendor.vendor_id, label: vendor.name),
      ];

  Future<void> _save(RetailSnapshot snapshot) async {
    final sku = _sku;
    final vendor_id = _vendor_id;
    final qty = parse_positive_int(_qty_controller.text);
    final cost = parse_money(_cost_controller.text);
    if (sku == null || vendor_id == null || qty == null || cost == null) return;

    setState(() => _is_saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      // The server makes the batch id, so the app only sends what the retailer chose.
      await ref.read(retail_store_provider.notifier).add_stock(
            sku: sku,
            vendor_id: vendor_id,
            qty: qty,
            unit_cost: cost,
          );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Stock added'),
      ));
    } catch (error) {
      if (mounted) setState(() => _is_saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(retail_store_provider).valueOrNull;
    final ready = _sku != null &&
        _vendor_id != null &&
        parse_positive_int(_qty_controller.text) != null &&
        parse_money(_cost_controller.text) != null &&
        !_is_saving;
    final typed_qty = parse_positive_int(_qty_controller.text);
    final typed_cost = parse_money(_cost_controller.text);
    final double? stock_total = (typed_qty == null || typed_cost == null)
        ? null
        : round_money(typed_qty * typed_cost);

    return Scaffold(
      appBar: AppBar(title: const Text('Add stock'), backgroundColor: AppColors.background),
      body: snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SearchableDropdown<String>(
                  label: 'Product',
                  sheet_title: 'Choose product',
                  options: product_options_all(snapshot),
                  selected: option_for(product_options_all(snapshot), _sku),
                  on_changed: (value) => setState(() => _sku = value),
                ),
                const SizedBox(height: 16),
                SearchableDropdown<String>(
                  label: 'Vendor',
                  sheet_title: 'Choose vendor',
                  options: _vendor_options(snapshot),
                  selected: option_for(_vendor_options(snapshot), _vendor_id),
                  on_changed: (value) => setState(() => _vendor_id = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: NumberField(
                        label: 'Quantity',
                        controller: _qty_controller,
                        on_changed: () => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NumberField(
                        label: 'Unit cost',
                        controller: _cost_controller,
                        decimal: true,
                        on_changed: () => setState(() {}),
                      ),
                    ),
                  ],
                ),
                if (stock_total != null) ...[
                  const SizedBox(height: 16),
                  TotalBanner(label: 'Invoice total', amount: stock_total),
                ],
                const SizedBox(height: 28),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: ready ? () => _save(snapshot) : null,
                  child: _is_saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save stock'),
                ),
              ],
            ),
    );
  }
}
