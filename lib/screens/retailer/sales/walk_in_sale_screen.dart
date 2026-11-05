import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/input_parsing.dart';
import '../../../models/warehouse_batch.dart';
import '../../../state/retail_providers.dart';
import '../../../state/retail_snapshot.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/retailer/batch_option.dart';
import '../../../widgets/retailer/product_option.dart';
import '../../../widgets/shared/number_field.dart';
import '../../../widgets/shared/searchable_dropdown.dart';
import '../../../widgets/shared/searchable_option.dart';
import '../../../invoices/round_money.dart';
import '../../../widgets/shared/total_banner.dart';

/// A customer buys on the spot, without a need-list. Price defaults to retail;
/// lower it for a discount.
class WalkInSaleScreen extends ConsumerStatefulWidget {
  const WalkInSaleScreen({super.key});

  @override
  ConsumerState<WalkInSaleScreen> createState() => _WalkInSaleScreenState();
}

class _WalkInSaleScreenState extends ConsumerState<WalkInSaleScreen> {
  String? _customer_id;
  String? _sku;
  String? _batch_id;
  final _qty_controller = TextEditingController();
  final _price_controller = TextEditingController();
  bool _is_saving = false;

  @override
  void dispose() {
    _qty_controller.dispose();
    _price_controller.dispose();
    super.dispose();
  }

  List<SearchableOption<String>> _customer_options(RetailSnapshot snapshot) => [
        for (final customer in snapshot.customers)
          SearchableOption<String>(value: customer.customer_id, label: customer.name),
      ];

  Future<void> _save(RetailSnapshot snapshot) async {
    final customer_id = _customer_id;
    final batch_id = _batch_id;
    final batch = batch_id == null ? null : snapshot.batch_by_id(batch_id);
    final qty = parse_positive_int(_qty_controller.text);
    final price = parse_money(_price_controller.text);
    if (customer_id == null || batch == null || qty == null || price == null) return;
    if (qty > batch.current_qty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Only ${batch.current_qty} left in ${batch.batch_id}'),
      ));
      return;
    }

    setState(() => _is_saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(retail_store_provider.notifier).sell_from_batch(
            batch_id: batch.batch_id,
            customer_id: customer_id,
            qty: qty,
            unit_price: price,
          );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Sale saved'),
      ));
    } catch (error) {
      if (mounted) setState(() => _is_saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(retail_store_provider).valueOrNull;
    if (snapshot == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final customer_options = _customer_options(snapshot);
    final product_options = product_options_in_stock(snapshot);
    final sku = _sku;
    final batches = sku == null ? <WarehouseBatch>[] : snapshot.batches_for_sku(sku);
    final batch_options = [
      for (final batch in batches)
        batch_option(
          batch: batch,
          product: snapshot.product_by_sku(batch.sku),
          today: DateTime.now(),
        ),
    ];
    final ready = _customer_id != null &&
        _batch_id != null &&
        parse_positive_int(_qty_controller.text) != null &&
        parse_money(_price_controller.text) != null &&
        !_is_saving;
    final typed_qty = parse_positive_int(_qty_controller.text);
    final typed_price = parse_money(_price_controller.text);
    final double? sale_total = (typed_qty == null || typed_price == null)
        ? null
        : round_money(typed_qty * typed_price);

    return Scaffold(
      appBar: AppBar(title: const Text('Walk-in sale'), backgroundColor: AppColors.background),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchableDropdown<String>(
            label: 'Customer',
            sheet_title: 'Choose customer',
            options: customer_options,
            selected: option_for(customer_options, _customer_id),
            on_changed: (value) => setState(() => _customer_id = value),
          ),
          const SizedBox(height: 16),
          SearchableDropdown<String>(
            label: 'Product',
            sheet_title: 'Choose product',
            options: product_options,
            selected: option_for(product_options, _sku),
            on_changed: (value) => setState(() {
              _sku = value;
              _batch_id = null;
              // Default to retail price; the retailer can lower it for a discount.
              final product = snapshot.product_by_sku(value);
              if (product != null) {
                _price_controller.text = product.default_retail_price.toStringAsFixed(2);
              }
            }),
          ),
          const SizedBox(height: 16),
          SearchableDropdown<String>(
            label: 'Batch',
            sheet_title: 'Choose batch',
            options: batch_options,
            selected: option_for(batch_options, _batch_id),
            enabled: sku != null,
            on_changed: (value) => setState(() => _batch_id = value),
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
                  label: 'Unit price',
                  controller: _price_controller,
                  decimal: true,
                  on_changed: () => setState(() {}),
                ),
              ),
            ],
          ),
          if (sale_total != null) ...[
            const SizedBox(height: 16),
            TotalBanner(label: 'Sale total', amount: sale_total),
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
                : const Text('Save sale'),
          ),
        ],
      ),
    );
  }
}
