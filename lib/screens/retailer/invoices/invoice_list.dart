import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../invoices/format_dollars.dart';
import '../../../invoices/invoice_search.dart';
import '../../../invoices/round_money.dart';
import '../../../invoices/group_ledger_invoices.dart';
import '../../../invoices/ledger_invoice.dart';
import '../../../models/ledger_row.dart';
import '../../../state/retail_snapshot.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shared/app_card.dart';
import 'invoice_detail_screen.dart';
import '../../../widgets/shared/state_views.dart';

/// All invoices of one kind (purchase or sale), newest first.
/// A summary at the top shows what is still open, and the search box filters
/// by party name or invoice number.
class InvoiceList extends StatefulWidget {
  const InvoiceList({super.key, required this.snapshot, required this.type});

  final RetailSnapshot snapshot;
  final TransactionType type;

  @override
  State<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _is_purchase => widget.type == TransactionType.purchase;

  String _party_name(LedgerInvoice invoice) => _is_purchase
      ? widget.snapshot.vendor_name(invoice.party_id)
      : widget.snapshot.customer_name(invoice.party_id);

  double _paid(LedgerInvoice invoice) =>
      round_money(widget.snapshot.paid_on_invoice(invoice.transaction_id));

  /// Money still open on one invoice, never below zero.
  double _open_amount(LedgerInvoice invoice) => open_amount_of(invoice, _paid(invoice));

  @override
  Widget build(BuildContext context) {
    final all = group_ledger_invoices(widget.snapshot.ledger, widget.type);

    if (all.isEmpty) {
      return EmptyState(
        icon: Icons.description_outlined,
        title: _is_purchase ? 'No purchase invoices yet' : 'No sales invoices yet',
        hint: 'Tap the green button to add one.',
      );
    }

    final outstanding = round_money(
      all.fold(0.0, (sum, invoice) => sum + _open_amount(invoice)),
    );
    final open_count = all.where((i) => _open_amount(i) > 0).length;

    final invoices = all
        .where((i) => invoice_matches_query(i, _party_name(i), _query))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _SummaryCard(
            label: _is_purchase ? 'To pay vendors' : 'To receive from customers',
            amount: outstanding,
            detail: outstanding <= 0
                ? 'Everything is settled'
                : '$open_count open ${open_count == 1 ? 'invoice' : 'invoices'}',
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search by party or invoice number',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.line),
              ),
            ),
          ),
        ),
        Expanded(
          child: invoices.isEmpty
              ? Center(
                  child: Text(
                    'No invoice matches "${_query.trim()}"',
                    style: const TextStyle(color: AppColors.ink_soft),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: invoices.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _invoice_card(context, invoices[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _invoice_card(BuildContext context, LedgerInvoice invoice) {
    final paid = _paid(invoice);
    final is_settled = paid + 0.005 >= invoice.total;
    final is_partial = !is_settled && paid > 0;
    final status = is_settled
        ? (_is_purchase ? 'Paid' : 'Received')
        : (is_partial ? 'Part ${_is_purchase ? 'paid' : 'received'}' : 'Unpaid');
    final color = is_settled
        ? AppColors.fresh
        : (is_partial ? AppColors.accent : AppColors.priority);

    return AppCard(
      on_tap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => InvoiceDetailScreen(
          transaction_id: invoice.transaction_id,
          type: widget.type,
        ),
      )),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              IconBadge(
                icon: _is_purchase
                    ? Icons.local_shipping_rounded
                    : Icons.receipt_long_rounded,
                color: _is_purchase ? AppColors.accent : AppColors.brand_dark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_party_name(invoice),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('d MMM yyyy').format(invoice.date)} · '
                      '${invoice.transaction_id}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.ink_soft, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(format_dollars(invoice.total),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  StatusPill(text: status, color: color),
                ],
              ),
            ],
          ),
          if (is_partial) ...[
            const SizedBox(height: 10),
            SoftBar(
              value: invoice.total <= 0 ? 0.0 : paid / invoice.total,
              color: AppColors.accent,
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.amount, required this.detail});

  final String label;
  final double amount;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final is_clear = amount <= 0;
    final color = is_clear ? AppColors.fresh : AppColors.priority;
    return AppCard(
      shadow: true,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBadge(
            icon: is_clear ? Icons.check_circle_rounded : Icons.account_balance_wallet_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
                const SizedBox(height: 2),
                Text(format_dollars(amount),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
              ],
            ),
          ),
          StatusPill(text: detail, color: color),
        ],
      ),
    );
  }
}
