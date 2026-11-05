import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/date_helpers.dart';
import '../../../core/suggest_allocations.dart';
import '../../../models/pickup_allocation.dart';
import '../../../state/retail_providers.dart';
import '../../../state/retail_snapshot.dart';
import '../../../theme/app_colors.dart';
import 'pickup_line_editor.dart';
import '../../../widgets/shared/app_card.dart';
import '../../../widgets/shared/skeleton.dart';
import '../../../widgets/shared/state_views.dart';

/// Picked Up flow. Day 2 batches are suggested first; the retailer can change
/// any batch, and the sale is only saved once every item is fully allocated.
class PickupScreen extends ConsumerStatefulWidget {
  const PickupScreen({
    super.key,
    required this.customer_id,
    required this.pickup_date,
  });

  final String customer_id;
  final DateTime pickup_date;

  @override
  ConsumerState<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends ConsumerState<PickupScreen> {
  // Built once from the first snapshot, so a reload never wipes the retailer's edits.
  Map<String, int>? _needed;
  Map<String, List<PickupAllocation>>? _picks;
  bool _is_saving = false;

  void _start_from(RetailSnapshot snapshot) {
    final needed = <String, int>{};
    for (final row in snapshot.open_need_rows_on(widget.pickup_date)) {
      if (row.customer_id != widget.customer_id) continue;
      needed[row.sku] = (needed[row.sku] ?? 0) + row.qty;
    }
    final picks = <String, List<PickupAllocation>>{};
    for (final entry in needed.entries) {
      final product = snapshot.product_by_sku(entry.key);
      picks[entry.key] = suggest_allocations(
        batches: snapshot.batches_for_sku(entry.key),
        qty: entry.value,
        unit_price: product?.default_retail_price ?? 0,
      );
    }
    _needed = needed;
    _picks = picks;
  }

  /// Batches that would give out more than they hold, across all the lines.
  List<String> _over_drawn(RetailSnapshot snapshot) {
    final taken = <String, int>{};
    for (final list in (_picks ?? {}).values) {
      for (final pick in list) {
        taken[pick.batch_id] = (taken[pick.batch_id] ?? 0) + pick.qty;
      }
    }
    return [
      for (final entry in taken.entries)
        if (entry.value > (snapshot.batch_by_id(entry.key)?.current_qty ?? 0)) entry.key,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final snapshot_async = ref.watch(retail_store_provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Picked Up'),
        backgroundColor: AppColors.background,
      ),
      body: snapshot_async.when(
        loading: () => const SkeletonList(count: 3),
        error: (error, _) => ErrorView(
        error: error,
        on_retry: () => ref.invalidate(retail_store_provider),
      ),
        data: (snapshot) {
          if (_needed == null) _start_from(snapshot);
          final needed = _needed!;
          final picks = _picks!;
          final over = _over_drawn(snapshot);
          final every_line_full = needed.keys.every((sku) {
            final picked = (picks[sku] ?? []).fold(0, (sum, p) => sum + p.qty);
            return picked == needed[sku];
          });
          final can_finish = every_line_full && over.isEmpty && !_is_saving;
          final lines_ready = needed.keys.where((sku) {
            final picked = (picks[sku] ?? []).fold(0, (sum, p) => sum + p.qty);
            return picked == needed[sku];
          }).length;
          final customer_name = snapshot.customer_name(widget.customer_id);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    AppCard(
                      shadow: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppColors.brand.withAlpha(31),
                                child: Text(
                                  customer_name.isEmpty ? '?' : customer_name[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: AppColors.brand_dark,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(customer_name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 20, fontWeight: FontWeight.w800)),
                              ),
                              StatusPill(
                                text: '$lines_ready of ${needed.length} ready',
                                color: lines_ready == needed.length
                                    ? AppColors.fresh
                                    : AppColors.accent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SoftBar(
                            value: needed.isEmpty ? 1.0 : lines_ready / needed.length,
                            color: lines_ready == needed.length
                                ? AppColors.fresh
                                : AppColors.accent,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Choose the batch for each item. Day 2 stock is listed first.',
                            style: TextStyle(color: AppColors.ink_soft, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final sku in needed.keys)
                      if (snapshot.product_by_sku(sku) != null)
                        PickupLineEditor(
                          key: ValueKey('pickup_$sku'),
                          product: snapshot.product_by_sku(sku)!,
                          batches: snapshot.batches_for_sku(sku),
                          today: date_only(DateTime.now()),
                          needed: needed[sku]!,
                          initial: picks[sku] ?? [],
                          on_changed: (list) => setState(() => picks[sku] = list),
                        ),
                    if (over.isNotEmpty)
                      Text('Not enough in stock for: ${over.join(', ')}',
                          style: const TextStyle(color: AppColors.priority)),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: can_finish ? _finish : null,
                      child: _is_saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(every_line_full
                              ? 'Mark Picked Up'
                              : 'Allocate every item first'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _finish() async {
    final picks = _picks;
    if (picks == null) return;
    setState(() => _is_saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(retail_store_provider.notifier).complete_pickup(
            customer_id: widget.customer_id,
            pickup_date: widget.pickup_date,
            allocations: [for (final list in picks.values) ...list],
          );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Picked up. Sales saved.'),
      ));
    } catch (error) {
      if (mounted) setState(() => _is_saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }
}
