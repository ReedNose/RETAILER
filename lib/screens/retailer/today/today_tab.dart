import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/date_helpers.dart';
import '../../../core/greeting.dart';
import '../../../core/morning_checklist.dart';
import '../../../models/need_list_row.dart';
import '../../../state/retail_providers.dart';
import '../../../state/retail_snapshot.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_style.dart';
import '../../../widgets/shared/app_card.dart';
import '../../../widgets/shared/skeleton.dart';
import '../../../widgets/shared/state_views.dart';
import 'morning_checklist_card.dart';
import 'pickup_customer_tile.dart';
import 'quick_actions.dart';

/// Today at a glance: summary, what to sell first, quick actions, the morning
/// checklist, then one tile per customer with open need-list rows.
class TodayTab extends ConsumerWidget {
  const TodayTab({super.key, required this.on_open_inventory});

  final VoidCallback on_open_inventory;

  /// "🥛×3  🍞×2" in the shop's product order.
  String _summary(RetailSnapshot snapshot, List<NeedListRow> rows) {
    final qty_by_sku = <String, int>{};
    for (final row in rows) {
      qty_by_sku[row.sku] = (qty_by_sku[row.sku] ?? 0) + row.qty;
    }
    return [
      for (final product in snapshot.products)
        if (qty_by_sku.containsKey(product.sku))
          '${product.emoji}×${qty_by_sku[product.sku]}',
    ].join('  ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot_async = ref.watch(retail_store_provider);

    return snapshot_async.when(
      loading: () => const SkeletonList(count: 5),
      error: (error, _) => ErrorView(
        error: error,
        on_retry: () => ref.invalidate(retail_store_provider),
      ),
      data: (snapshot) {
        final now = DateTime.now();
        final today = date_only(now);
        final checklist = build_morning_checklist(snapshot, today);
        final today_rows = snapshot.open_need_rows_on(today);

        // Distinct customers, in the order they first appear.
        final customer_ids = <String>[];
        for (final row in today_rows) {
          if (!customer_ids.contains(row.customer_id)) {
            customer_ids.add(row.customer_id);
          }
        }

        final to_prep = checklist.fold(0, (sum, l) => sum + l.to_buy_or_prep);
        final items_needed = today_rows.fold(0, (sum, r) => sum + r.qty);
        final priority = snapshot.priority_batches(today);

        return RefreshIndicator(
          onRefresh: () => ref.read(retail_store_provider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _HeroCard(
                date_text: DateFormat('EEEE, d MMM').format(today),
                greeting: greeting_for(now),
                pickups: customer_ids.length,
                items: items_needed,
                to_prep: to_prep,
              ),
              if (priority.isNotEmpty) ...[
                const SizedBox(height: 14),
                _PriorityBanner(count: priority.length, on_tap: on_open_inventory),
              ],
              const SizedBox(height: 14),
              const QuickActions(),
              const SizedBox(height: 18),
              MorningChecklistCard(lines: checklist, snapshot: snapshot),
              const SizedBox(height: 22),
              SectionHeader(
                'Pickups today',
                trailing: customer_ids.isEmpty
                    ? null
                    : StatusPill(
                        text: '${customer_ids.length} waiting',
                        color: AppColors.accent,
                      ),
              ),
              if (customer_ids.isEmpty)
                const AppCard(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text('No open need-lists for today.',
                        style: TextStyle(color: AppColors.ink_soft)),
                  ),
                ),
              for (final customer_id in customer_ids)
                PickupCustomerTile(
                  customer_id: customer_id,
                  customer_name: snapshot.customer_name(customer_id),
                  pickup_date: today,
                  summary: _summary(
                    snapshot,
                    today_rows.where((r) => r.customer_id == customer_id).toList(),
                  ),
                  item_count: today_rows
                      .where((r) => r.customer_id == customer_id)
                      .fold(0, (sum, r) => sum + r.qty),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.date_text,
    required this.greeting,
    required this.pickups,
    required this.items,
    required this.to_prep,
  });

  final String date_text;
  final String greeting;
  final int pickups;
  final int items;
  final int to_prep;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.hero_gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadow.lift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date_text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(greeting,
              style: const TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _HeroStat(value: '$pickups', label: 'pickups')),
              const SizedBox(width: 10),
              Expanded(child: _HeroStat(value: '$items', label: 'items needed')),
              const SizedBox(width: 10),
              Expanded(child: _HeroStat(value: '$to_prep', label: 'to buy / prep')),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(36),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _PriorityBanner extends StatelessWidget {
  const _PriorityBanner({required this.count, required this.on_tap});

  final int count;
  final VoidCallback on_tap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.priority_bg,
      border_color: soft_tint(AppColors.priority, 0.3),
      on_tap: on_tap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const IconBadge(
            icon: Icons.local_fire_department_rounded,
            color: AppColors.priority,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1
                      ? '1 batch is on its last day'
                      : '$count batches are on their last day',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                const Text('Sell these first. Tap to see them.',
                    style: TextStyle(color: AppColors.ink_soft, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.priority),
        ],
      ),
    );
  }
}
