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

/// Expired or damaged stock. Valued at the batch's purchase cost by the repository.
class SpoilageScreen extends ConsumerStatefulWidget {
  const SpoilageScreen({super.key, this.initial_batch});

  final WarehouseBatch? initial_batch;

  @override
  ConsumerState<SpoilageScreen> createState() => _SpoilageScreenState();
}

class _SpoilageScreenState extends ConsumerState<SpoilageScreen> {
  String? _sku;
  String? _batch_id;
  final _qty_controller = TextEditingController();
  bool _is_saving = false;

  @override
  void initState() {
    super.initState();
    final batch = widget.initial_batch;
    if (batch != null) {
      _sku = batch.sku;
      _batch_id = batch.batch_id;
    }
  }

  @override
  void dispose() {
    _qty_controller.dispose();
    super.dispose();
  }

  Future<void> _save(RetailSnapshot snapshot) async {
    final batch_id = _batch_id;
    final batch = batch_id == null ? null : snapshot.batch_by_id(batch_id);
    final qty = parse_positive_int(_qty_controller.text);
    if (batch == null || qty == null) return;
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
      await ref.read(retail_store_provider.notifier).log_spoilage(
            batch_id: batch.batch_id,
            qty: qty,
          );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Spoilage logged'),
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
    final ready = _batch_id != null && parse_positive_int(_qty_controller.text) != null && !_is_saving;

    return Scaffold(
      appBar: AppBar(title: const Text('Log spoilage'), backgroundColor: AppColors.background),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SearchableDropdown<String>(
            label: 'Product',
            sheet_title: 'Choose product',
            options: product_options,
            selected: option_for(product_options, _sku),
            on_changed: (value) => setState(() {
              _sku = value;
              _batch_id = null;
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
          NumberField(
            label: 'Quantity lost',
            controller: _qty_controller,
            on_changed: () => setState(() {}),
          ),
          const SizedBox(height: 28),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.priority,
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
                : const Text('Log spoilage'),
          ),
        ],
      ),
    );
  }
}
