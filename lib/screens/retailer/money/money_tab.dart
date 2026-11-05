import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/date_helpers.dart';
import '../../../invoices/build_invoice_data.dart';
import '../../../invoices/current_balance.dart';
import '../../../invoices/format_dollars.dart';
import '../../../invoices/invoice_models.dart';
import '../../../invoices/share_invoice_pdf.dart';
import '../../../state/retail_providers.dart';
import '../../../state/retail_snapshot.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/retailer/customer_option.dart';
import '../../../widgets/shared/app_card.dart';
import '../../../widgets/shared/searchable_dropdown.dart';
import '../../../widgets/shared/searchable_option.dart';
import '../../../widgets/shared/skeleton.dart';
import '../../../widgets/shared/state_views.dart';
import 'invoice_date_field.dart';
import 'invoice_preview_card.dart';
import 'receive_payment_screen.dart';

typedef _Debtor = ({String customer_id, String name, double amount});

/// Who owes what, then: pick a customer and a day, see the invoice,
/// share it as PDF, take payments.
class MoneyTab extends ConsumerStatefulWidget {
  const MoneyTab({super.key});

  @override
  ConsumerState<MoneyTab> createState() => _MoneyTabState();
}

class _MoneyTabState extends ConsumerState<MoneyTab> {
  String? _customer_id;
  DateTime _day = date_only(DateTime.now());
  bool _is_sharing = false;

  Future<void> _share(InvoiceData invoice) async {
    setState(() => _is_sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    final shared = await share_invoice_pdf(invoice);
    if (!mounted) return;
    setState(() => _is_sharing = false);
    if (!shared) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not share the invoice PDF'),
      ));
    }
  }

  /// Customers with money still owed, biggest first.
  List<_Debtor> _debtors(RetailSnapshot snapshot) {
    final now = DateTime.now();
    final list = <_Debtor>[];
    for (final customer in snapshot.customers) {
      final owed = current_balance(
        ledger: snapshot.ledger,
        payments: snapshot.payments,
        customer_id: customer.customer_id,
        now: now,
      );
      if (owed > 0.005) {
        list.add((customer_id: customer.customer_id, name: customer.name, amount: owed));
      }
    }
    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final snapshot_async = ref.watch(retail_store_provider);

    return snapshot_async.when(
      loading: () => const SkeletonList(count: 4),
      error: (error, _) => ErrorView(
        error: error,
        on_retry: () => ref.invalidate(retail_store_provider),
      ),
      data: (snapshot) {
        final options = customer_options(snapshot);
        final customer_id = _customer_id;
        final invoice = customer_id == null
            ? null
            : build_invoice_data(snapshot: snapshot, customer_id: customer_id, day: _day);
        final debtors = _debtors(snapshot);

        return RefreshIndicator(
          onRefresh: () => ref.read(retail_store_provider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _OwedCard(
                debtors: debtors,
                on_pick: (id) => setState(() => _customer_id = id),
              ),
              const SizedBox(height: 22),
              const SectionHeader('Customer invoice'),
              SearchableDropdown<String>(
                label: 'Customer',
                sheet_title: 'Choose customer',
                options: options,
                selected: option_for(options, _customer_id),
                on_changed: (value) => setState(() => _customer_id = value),
              ),
              const SizedBox(height: 14),
              InvoiceDateField(
                day: _day,
                on_changed: (day) => setState(() => _day = day),
              ),
              const SizedBox(height: 16),
              if (customer_id == null)
                const AppCard(
                  padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                  child: Center(
                    child: Text('Choose a customer to see their invoice.',
                        style: TextStyle(color: AppColors.ink_soft)),
                  ),
                )
              else if (invoice == null)
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                  child: Center(
                    child: Text(
                      'No sales for ${snapshot.customer_name(customer_id)} on this date.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.ink_soft),
                    ),
                  ),
                )
              else
                InvoicePreviewCard(invoice: invoice),
              const SizedBox(height: 18),
              if (invoice != null)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _is_sharing ? null : () => _share(invoice),
                  icon: const Icon(Icons.share_rounded),
                  label: Text(_is_sharing ? 'Preparing PDF...' : 'Share invoice PDF'),
                ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: customer_id == null
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) =>
                              ReceivePaymentScreen(initial_customer_id: customer_id),
                        )),
                icon: const Icon(Icons.payments_rounded),
                label: const Text('Receive payment'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Customers owe you $X" with the biggest balances; tap one to open their invoice.
class _OwedCard extends StatelessWidget {
  const _OwedCard({required this.debtors, required this.on_pick});

  final List<_Debtor> debtors;
  final ValueChanged<String> on_pick;

  static const _shown = 4;

  @override
  Widget build(BuildContext context) {
    final total = debtors.fold(0.0, (sum, d) => sum + d.amount);
    final is_settled = debtors.isEmpty;
    final extra = debtors.length - _shown;

    return AppCard(
      shadow: true,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: is_settled
                    ? Icons.check_circle_rounded
                    : Icons.account_balance_wallet_rounded,
                color: is_settled ? AppColors.fresh : AppColors.priority,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(is_settled ? 'All settled up' : 'Customers owe you',
                        style: const TextStyle(color: AppColors.ink_soft, fontSize: 13)),
                    Text(
                      is_settled ? 'Nobody owes anything' : format_dollars(total),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!is_settled) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            for (final debtor in debtors.take(_shown))
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => on_pick(debtor.customer_id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.accent_tint,
                        child: Text(
                          debtor.name.isEmpty ? '?' : debtor.name[0].toUpperCase(),
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(debtor.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Text(format_dollars(debtor.amount),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: AppColors.priority)),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.ink_faint),
                    ],
                  ),
                ),
              ),
            if (extra > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('and $extra more',
                    style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
              ),
          ],
        ],
      ),
    );
  }
}
