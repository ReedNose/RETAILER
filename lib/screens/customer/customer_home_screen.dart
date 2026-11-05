import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_config.dart';
import '../../core/date_helpers.dart';
import '../../core/first_or_null.dart';
import '../../models/product.dart';
import '../../state/cart_providers.dart';
import '../../state/log_out.dart';
import '../../state/retail_providers.dart';
import '../../state/retail_snapshot.dart';
import '../../state/session_providers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';
import '../../widgets/customer/checkout_bar.dart';
import '../../widgets/customer/order_review_sheet.dart';
import '../../widgets/customer/product_card.dart';
import '../../widgets/shared/app_card.dart';
import '../../widgets/shared/skeleton.dart';
import '../../widgets/shared/state_views.dart';
import 'send_need_list_action.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> _categories(RetailSnapshot snapshot) {
    final seen = <String>[];
    for (final product in snapshot.products) {
      if (product.category.isNotEmpty && !seen.contains(product.category)) {
        seen.add(product.category);
      }
    }
    return seen;
  }

  List<Product> _visible(RetailSnapshot snapshot) {
    final query = _query.trim().toLowerCase();
    return [
      for (final product in snapshot.products)
        if ((_category == null || product.category == _category) &&
            (query.isEmpty || product.name.toLowerCase().contains(query)))
          product,
    ];
  }

  /// What this customer already sent for the pickup day, sku -> qty.
  Map<String, int> _sent_for(RetailSnapshot snapshot, String? customer_id, DateTime day) {
    final sent = <String, int>{};
    if (customer_id == null) return sent;
    for (final row in snapshot.need_list) {
      if (row.customer_id == customer_id &&
          !row.is_done &&
          is_same_date(row.pickup_date, day)) {
        sent[row.sku] = (sent[row.sku] ?? 0) + row.qty;
      }
    }
    return sent;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(current_user_provider);
    final snapshot_async = ref.watch(retail_store_provider);
    final cart = ref.watch(cart_provider);
    final item_count = ref.watch(cart_item_count_provider);
    final is_sending = ref.watch(is_sending_provider);

    final pickup_day = date_only(DateTime.now().add(const Duration(days: 1)));
    final pickup_label = 'Pickup tomorrow · ${DateFormat('EEE d MMM').format(pickup_day)}';

    return Scaffold(
      body: SafeArea(
        child: snapshot_async.when(
          loading: () => const SkeletonGrid(),
          error: (error, _) => ErrorView(
            error: error,
            on_retry: () => ref.invalidate(retail_store_provider),
          ),
          data: (snapshot) {
            final customer = first_where_or_null(
              snapshot.customers,
              (c) => c.customer_id == user?.customer_id,
            );
            final first_name = customer?.name.split(' ').first ?? 'there';
            final categories = _categories(snapshot);
            final products = _visible(snapshot);
            final sent = _sent_for(snapshot, user?.customer_id, pickup_day);
            final show_sent = sent.isNotEmpty && cart.isEmpty;

            void send() {
              if (user != null) {
                send_need_list_action(context: context, ref: ref, user: user);
              }
            }

            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => ref.read(retail_store_provider.notifier).refresh(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _Header(
                          first_name: first_name,
                          pickup_label: pickup_label,
                          on_logout: () => log_out(ref),
                        ),
                      ),
                      if (show_sent)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: _SentOrderCard(
                              count: sent.values.fold(0, (sum, qty) => sum + qty),
                              summary: [
                                for (final product in snapshot.products)
                                  if (sent.containsKey(product.sku))
                                    '${product.emoji} ×${sent[product.sku]}',
                              ].join('   '),
                              on_change: () =>
                                  ref.read(cart_provider.notifier).set_all(sent),
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: _SearchAndFilters(
                          search: _search,
                          has_query: _query.isNotEmpty,
                          on_query: (value) => setState(() => _query = value),
                          on_clear: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                          categories: categories,
                          selected: _category,
                          on_select: (value) => setState(() => _category = value),
                        ),
                      ),
                      if (products.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'No products found',
                            hint: 'Try another name or category.',
                          ),
                        )
                      else
                        SliverPadding(
                          // Bottom padding leaves room for the floating bar.
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.74,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final product = products[index];
                                return TweenAnimationBuilder<double>(
                                  key: ValueKey(product.sku),
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: Duration(
                                      milliseconds: 260 + math.min(index, 8) * 40),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, t, child) => Opacity(
                                    opacity: t,
                                    child: Transform.translate(
                                      offset: Offset(0, (1 - t) * 16),
                                      child: child,
                                    ),
                                  ),
                                  child: ProductCard(
                                    product: product,
                                    stock: snapshot.total_stock_for_sku(product.sku),
                                    qty: cart[product.sku] ?? 0,
                                    on_increment: () => ref
                                        .read(cart_provider.notifier)
                                        .increment(product.sku),
                                    on_decrement: () => ref
                                        .read(cart_provider.notifier)
                                        .decrement(product.sku),
                                  ),
                                );
                              },
                              childCount: products.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CheckoutBar(
                    item_count: item_count,
                    is_sending: is_sending,
                    on_send: send,
                    on_review: () => show_order_review_sheet(
                      context: context,
                      pickup_label: pickup_label,
                      on_send: send,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.first_name,
    required this.pickup_label,
    required this.on_logout,
  });

  final String first_name;
  final String pickup_label;
  final VoidCallback on_logout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 16),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop_name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Hi, $first_name 👋',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                StatusPill(
                  text: pickup_label,
                  color: AppColors.accent,
                  icon: Icons.event_rounded,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: on_logout,
            icon: const Icon(Icons.logout_rounded, color: AppColors.ink_soft),
          ),
        ],
      ),
    );
  }
}

class _SentOrderCard extends StatelessWidget {
  const _SentOrderCard({
    required this.count,
    required this.summary,
    required this.on_change,
  });

  final int count;
  final String summary;
  final VoidCallback on_change;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.brand_tint,
      border_color: soft_tint(AppColors.brand, 0.3),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          const IconBadge(icon: Icons.check_circle_rounded, color: AppColors.brand_dark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Order sent for tomorrow',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('$count ${count == 1 ? 'item' : 'items'}  ·  $summary',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
              ],
            ),
          ),
          TextButton(onPressed: on_change, child: const Text('Change')),
        ],
      ),
    );
  }
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({
    required this.search,
    required this.has_query,
    required this.on_query,
    required this.on_clear,
    required this.categories,
    required this.selected,
    required this.on_select,
  });

  final TextEditingController search;
  final bool has_query;
  final ValueChanged<String> on_query;
  final VoidCallback on_clear;
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> on_select;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: TextField(
            controller: search,
            onChanged: on_query,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: has_query
                  ? IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: on_clear,
                    )
                  : null,
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
        if (categories.length > 1)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'All',
                  is_selected: selected == null,
                  on_tap: () => on_select(null),
                ),
                for (final category in categories)
                  _CategoryChip(
                    label: category,
                    is_selected: selected == category,
                    on_tap: () => on_select(category),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.is_selected,
    required this.on_tap,
  });

  final String label;
  final bool is_selected;
  final VoidCallback on_tap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: is_selected ? AppColors.ink : AppColors.card,
        shape: StadiumBorder(
          side: BorderSide(color: is_selected ? AppColors.ink : AppColors.line),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: on_tap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Text(
              label,
              style: TextStyle(
                color: is_selected ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
