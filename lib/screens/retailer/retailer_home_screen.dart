import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/date_helpers.dart';
import '../../state/log_out.dart';
import '../../state/retail_providers.dart';
import '../../theme/app_colors.dart';
import 'inventory/inventory_tab.dart';
import 'invoices/invoices_tab.dart';
import 'money/money_tab.dart';
import 'reports/reports_tab.dart';
import 'today/today_tab.dart';

/// Retailer shell: Today, Inventory, Reports, Money and Invoices.
/// Today shows how many customers are waiting; Inventory how many batches are on Day 2.
class RetailerHomeScreen extends ConsumerStatefulWidget {
  const RetailerHomeScreen({super.key});

  @override
  ConsumerState<RetailerHomeScreen> createState() => _RetailerHomeScreenState();
}

class _RetailerHomeScreenState extends ConsumerState<RetailerHomeScreen> {
  int _tab = 0;

  static const _titles = ['Today', 'Inventory', 'Reports', 'Money', 'Invoices'];

  Widget _badged(IconData icon, int count, Color color) => Badge(
        isLabelVisible: count > 0,
        backgroundColor: color,
        label: Text('$count'),
        child: Icon(icon),
      );

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(retail_store_provider).valueOrNull;
    final today = date_only(DateTime.now());
    var waiting = 0;
    var day_two = 0;
    if (snapshot != null) {
      waiting = {
        for (final row in snapshot.open_need_rows_on(today)) row.customer_id,
      }.length;
      day_two = snapshot.priority_batches(today).length;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => log_out(ref),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          TodayTab(on_open_inventory: () => setState(() => _tab = 1)),
          const InventoryTab(),
          const ReportsTab(),
          const MoneyTab(),
          const InvoicesTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) => setState(() => _tab = index),
          destinations: [
            NavigationDestination(
              icon: _badged(Icons.wb_sunny_outlined, waiting, AppColors.accent),
              selectedIcon: _badged(Icons.wb_sunny_rounded, waiting, AppColors.accent),
              label: 'Today',
            ),
            NavigationDestination(
              icon: _badged(Icons.inventory_2_outlined, day_two, AppColors.priority),
              selectedIcon: _badged(Icons.inventory_2_rounded, day_two, AppColors.priority),
              label: 'Inventory',
            ),
            const NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Reports',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Money',
            ),
            const NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description_rounded),
              label: 'Invoices',
            ),
          ],
        ),
      ),
    );
  }
}
