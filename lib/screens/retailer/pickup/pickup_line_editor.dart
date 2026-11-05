import 'package:flutter/material.dart';

import '../../../core/input_parsing.dart';
import '../../../models/pickup_allocation.dart';
import '../../../models/product.dart';
import '../../../models/warehouse_batch.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/retailer/batch_option.dart';
import '../../../widgets/shared/number_field.dart';
import '../../../widgets/shared/searchable_dropdown.dart';
import '../../../widgets/shared/searchable_option.dart';

/// One mutable row: which batch, how many, at what price.
class _Slice {
  _Slice({this.batch_id, required int qty, required double price})
      : qty_controller = TextEditingController(text: '$qty'),
        price_controller = TextEditingController(text: price.toStringAsFixed(2));

  String? batch_id;
  final TextEditingController qty_controller;
  final TextEditingController price_controller;

  void dispose() {
    qty_controller.dispose();
    price_controller.dispose();
  }
}

/// Allocates one need line (one product) across batches. The retailer can
/// split the need over several batches and change the price for a discount.
class PickupLineEditor extends StatefulWidget {
  const PickupLineEditor({
    super.key,
    required this.product,
    required this.batches,
    required this.today,
    required this.needed,
    required this.initial,
    required this.on_changed,
  });

  final Product product;
  final List<WarehouseBatch> batches; // oldest first
  final DateTime today;
  final int needed;
  final List<PickupAllocation> initial;
  final ValueChanged<List<PickupAllocation>> on_changed;

  @override
  State<PickupLineEditor> createState() => _PickupLineEditorState();
}

class _PickupLineEditorState extends State<PickupLineEditor> {
  final List<_Slice> _slices = [];

  @override
  void initState() {
    super.initState();
    for (final pick in widget.initial) {
      _slices.add(_Slice(
        batch_id: pick.batch_id,
        qty: pick.qty,
        price: pick.unit_price,
      ));
    }
    // Always show at least one row, even when there is no stock to suggest.
    if (_slices.isEmpty) {
      _slices.add(_Slice(
        qty: widget.needed,
        price: widget.product.default_retail_price,
      ));
    }
  }

  @override
  void dispose() {
    for (final slice in _slices) {
      slice.dispose();
    }
    super.dispose();
  }

  int get _picked => _slices
      .where((s) => s.batch_id != null)
      .fold(0, (sum, s) => sum + (parse_positive_int(s.qty_controller.text) ?? 0));

  /// Only complete rows (batch, qty and price all set) are reported upward.
  void _emit() {
    final picks = <PickupAllocation>[];
    for (final slice in _slices) {
      final batch_id = slice.batch_id;
      final qty = parse_positive_int(slice.qty_controller.text);
      final price = parse_money(slice.price_controller.text);
      if (batch_id == null || qty == null || price == null) continue;
      picks.add(PickupAllocation(batch_id: batch_id, qty: qty, unit_price: price));
    }
    widget.on_changed(picks);
  }

  void _changed() {
    setState(() {});
    _emit();
  }

  void _add_slice() {
    final remaining = widget.needed - _picked;
    setState(() {
      _slices.add(_Slice(
        qty: remaining > 0 ? remaining : 1,
        price: widget.product.default_retail_price,
      ));
    });
    _emit();
  }

  void _remove_slice(int index) {
    setState(() {
      final removed = _slices.removeAt(index);
      WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      for (final batch in widget.batches)
        batch_option(batch: batch, product: widget.product, today: widget.today),
    ];
    final remaining = widget.needed - _picked;
    final status = remaining > 0
        ? 'Need $remaining more'
        : remaining < 0
            ? 'Picked ${-remaining} too many'
            : 'All ${widget.needed} picked ✓';
    final ok = remaining == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.product.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              Text(status,
                  style: TextStyle(
                    color: ok ? AppColors.fresh : AppColors.priority,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _slices.length; i++) _slice_row(i, options),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _add_slice,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Another batch'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slice_row(int index, List<SearchableOption<String>> options) {
    final slice = _slices[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: SearchableDropdown<String>(
              label: 'Batch',
              sheet_title: 'Choose batch',
              options: options,
              selected: option_for(options, slice.batch_id),
              on_changed: (value) {
                slice.batch_id = value;
                _changed();
              },
            ),
          ),
          const SizedBox(width: 8),
          NumberField(
            label: 'Qty',
            controller: slice.qty_controller,
            width: 60,
            on_changed: _changed,
          ),
          const SizedBox(width: 8),
          NumberField(
            label: 'Price',
            controller: slice.price_controller,
            decimal: true,
            width: 76,
            on_changed: _changed,
          ),
          if (_slices.length > 1)
            IconButton(
              tooltip: 'Remove batch',
              onPressed: () => _remove_slice(index),
              icon: const Icon(Icons.close_rounded, color: AppColors.ink_soft),
            ),
        ],
      ),
    );
  }
}
