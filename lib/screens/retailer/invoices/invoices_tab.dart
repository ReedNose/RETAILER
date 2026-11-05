import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/ledger_row.dart';
import '../../../state/retail_providers.dart';
import '../../../theme/app_colors.dart';
import 'entry/invoice_entry_screen.dart';
import 'invoice_list.dart';
import '../../../widgets/shared/state_views.dart';

/// Two tabs: Purchase invoices (from vendors) and Sales invoices (to
/// customers). An invoice is every ledger row that shares one transaction_id.
/// The green button starts a new invoice of the tab you are on.
class InvoicesTab extends ConsumerStatefulWidget {
  const InvoicesTab({super.key});

  @override
  ConsumerState<InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends ConsumerState<InvoicesTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this)
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  TransactionType get _type =>
      _tabs.index == 0 ? TransactionType.purchase : TransactionType.sale;

  @override
  Widget build(BuildContext context) {
    final snapshot_async = ref.watch(retail_store_provider);

    return Stack(
      children: [
        Column(
          children: [
            TabBar(
              controller: _tabs,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.ink_soft,
              indicatorColor: AppColors.accent,
              tabs: const [Tab(text: 'Purchases'), Tab(text: 'Sales')],
            ),
            Expanded(
              child: snapshot_async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorView(
        error: error,
        on_retry: () => ref.invalidate(retail_store_provider),
      ),
                data: (snapshot) => TabBarView(
                  controller: _tabs,
                  children: [
                    InvoiceList(snapshot: snapshot, type: TransactionType.purchase),
                    InvoiceList(snapshot: snapshot, type: TransactionType.sale),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => InvoiceEntryScreen(type: _type),
            )),
            icon: const Icon(Icons.add_rounded),
            label: Text(
              _type == TransactionType.purchase ? 'New purchase' : 'New sale',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
