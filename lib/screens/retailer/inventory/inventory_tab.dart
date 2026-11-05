import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/batch_freshness.dart';
import '../../../core/date_helpers.dart';
import '../../../invoices/format_dollars.dart';
import '../../../models/ledger_row.dart';
import '../../../models/warehouse_batch.dart';
import '../../../state/retail_providers.dart';
import '../../../state/retail_snapshot.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shared/app_card.dart';
import '../../../widgets/shared/skeleton.dart';
import '../../../widgets/shared/state_views.dart';
import '../sales/walk_in_sale_screen.dart';
import 'add_stock_screen.dart';
import 'inventory_batch_card.dart';
import 'spoilage_screen.dart';

/// Live stock, oldest first, so Day 2 batches sit at the top under their date.
/// A summary strip, search, and a "Day 2 only" filter sit above the list.
class InventoryTab extends ConsumerStatefulWidget {
  const InventoryTab({super.key});

  @override
  ConsumerState<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<InventoryTab> {
  final _search = TextEditingController();
  String _query = '';
  bool _priority_only = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(RetailSnapshot snapshot, WarehouseBatch batch, DateTime today) {
    final product = snapshot.product_by_sku(batch.sku);
    if (_priority_only &&
        !is_priority_batch(
          batch_date: batch.batch_date,
          shelf_life_days: product?.shelf_life_days ?? 2,
          today: today,
        )) {
      return false;
    }
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return true;
    final name = (product?.name ?? batch.sku).toLowerCase();
    return name.contains(query) || batch.batch_id.toLowerCase().contains(query);
  }

  @override
  Widget build(BuildContext context) {
    final snapshot_async = ref.watch(retail_store_provider);

    return snapshot_async.when(
      loading: () => const SkeletonList(count: 5),
      error: (error, _) => ErrorView(
        error: error,
        on_retry: () => ref.invalidate(retail_store_provider),
      ),
      data: (snapshot) {
        final today = date_only(DateTime.now());

        // What each batch started with, from its purchase rows.
        final bought = <String, int>{};
        for (final row in snapshot.ledger) {
          if (row.transaction_type == TransactionType.purchase) {
            bought[row.batch_id] = (bought[row.batch_id] ?? 0) + row.qty.abs();
          }
        }

        final batches = <WarehouseBatch>[
          for (final batch in snapshot.warehouse)
            if (_matches(snapshot, batch, today)) batch,
        ]..sort((a, b) => a.batch_date.compareTo(b.batch_date));

        final cards = <Widget>[];
        DateTime? group_day;
        for (final batch in batches) {
          if (group_day == null || !is_same_date(group_day, batch.batch_date)) {
            group_day = batch.batch_date;
            cards.add(_DateHeader(
              date: batch.batch_date,
              label: batch_age_label(batch.batch_date, today),
            ));
          }
          cards.add(InventoryBatchCard(
            batch: batch,
            product: snapshot.product_by_sku(batch.sku),
            today: today,
            bought_qty: bought[batch.batch_id],
            on_spoil: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => SpoilageScreen(initial_batch: batch),
            )),
          ));
        }

        final priority_count = snapshot.priority_batches(today).length;

        return RefreshIndicator(
          onRefresh: () => ref.read(retail_store_provider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const AddStockScreen(),
                      )),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add stock'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const WalkInSaleScreen(),
                      )),
                      icon: const Icon(Icons.point_of_sale_rounded),
                      label: const Text('Walk-in sale'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Row(
                  children: [
                    _SummaryItem(
                      value: '${snapshot.units_on_shelf}',
                      label: 'units on shelf',
                    ),
                    const _SummaryDivider(),
                    _SummaryItem(
                      value: format_dollars(snapshot.shelf_retail_value),
                      label: 'retail value',
                    ),
                    const _SummaryDivider(),
                    _SummaryItem(
                      value: '$priority_count',
                      label: 'on Day 2',
                      color: priority_count > 0 ? AppColors.priority : AppColors.fresh,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search product or batch',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _search.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.line),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilterChip(
                    label: const Text('Day 2'),
                    avatar: const Icon(Icons.local_fire_department_rounded,
                        size: 18, color: AppColors.priority),
                    selected: _priority_only,
                    selectedColor: AppColors.priority_bg,
                    showCheckmark: false,
                    onSelected: (value) => setState(() => _priority_only = value),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (snapshot.warehouse.isEmpty)
                const SizedBox(
                  height: 320,
                  child: EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No stock on the shelf',
                    hint: 'Tap Add stock when a delivery arrives.',
                  ),
                )
              else if (cards.isEmpty)
                const SizedBox(
                  height: 280,
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No batches match',
                    hint: 'Clear the search or the Day 2 filter.',
                  ),
                )
              else
                ...cards,
            ],
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.value, required this.label, this.color = AppColors.ink});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.line);
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date, required this.label});

  final DateTime date;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8, left: 2),
      child: Text(
        '${DateFormat('EEE d MMM').format(date)} · $label',
        style: const TextStyle(
            fontWeight: FontWeight.w700, color: AppColors.ink_soft, fontSize: 13),
      ),
    );
  }
}
