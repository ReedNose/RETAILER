import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/input_parsing.dart';
import '../../../invoices/format_dollars.dart';
import '../../../invoices/group_ledger_invoices.dart';
import '../../../invoices/ledger_invoice.dart';
import '../../../invoices/round_money.dart';
import '../../../invoices/share_ledger_invoice_pdf.dart';
import '../../../models/ledger_row.dart';
import '../../../state/retail_providers.dart';
import '../../../state/retail_snapshot.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_style.dart';
import '../../../widgets/shared/app_card.dart';
import '../../../widgets/shared/skeleton.dart';

/// One invoice: date, who, every line (product, qty × unit price, amount), then only the
/// amount and the payment (Paid on a purchase, Received on a sale).
class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({
    super.key,
    required this.transaction_id,
    required this.type,
  });

  final String transaction_id;
  final TransactionType type;

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  bool _is_sharing = false;

  bool get _is_purchase => widget.type == TransactionType.purchase;

  Future<void> _share(LedgerInvoice invoice, RetailSnapshot snapshot) async {
    setState(() => _is_sharing = true);
    final messenger = ScaffoldMessenger.of(context);
    final shared = await share_ledger_invoice_pdf(invoice, snapshot);
    if (!mounted) return;
    setState(() => _is_sharing = false);
    if (!shared) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Could not share the invoice PDF'),
      ));
    }
  }

  Future<void> _record_payment(double open_amount) async {
    final verb = _is_purchase ? 'Paid' : 'Received';
    final controller = TextEditingController(text: open_amount.toStringAsFixed(2));
    final amount = await showDialog<double>(
      context: context,
      builder: (dialog_context) => AlertDialog(
        title: Text('Record $verb'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '\$ ',
            helperText: 'Still open: ${format_dollars(open_amount)}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog_context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = parse_money(controller.text);
              if (value == null || value <= 0) return;
              Navigator.of(dialog_context).pop(value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (amount == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(retail_store_provider.notifier).record_invoice_payment(
            transaction_id: widget.transaction_id,
            amount: amount,
          );
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('$verb saved'),
      ));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(retail_store_provider).valueOrNull;
    final invoices = snapshot == null
        ? <LedgerInvoice>[]
        : group_ledger_invoices(snapshot.ledger, widget.type)
            .where((i) => i.transaction_id == widget.transaction_id)
            .toList();
    final invoice = invoices.isEmpty ? null : invoices.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(_is_purchase ? 'Purchase invoice' : 'Sales invoice'),
        backgroundColor: AppColors.background,
      ),
      body: (snapshot == null || invoice == null)
          ? const SkeletonList(count: 3)
          : _body(invoice, snapshot),
    );
  }

  Widget _body(LedgerInvoice invoice, RetailSnapshot snapshot) {
    final party_name = _is_purchase
        ? snapshot.vendor_name(invoice.party_id)
        : snapshot.customer_name(invoice.party_id);
    final paid = round_money(snapshot.paid_on_invoice(invoice.transaction_id));
    final open_amount = round_money(invoice.total - paid);
    final payment_label = _is_purchase ? 'Paid' : 'Received';
    final is_settled = open_amount <= 0;
    final is_partial = !is_settled && paid > 0;
    final status_color = is_settled
        ? AppColors.fresh
        : (is_partial ? AppColors.accent : AppColors.priority);
    final status_text = is_settled
        ? '$payment_label in full'
        : (is_partial ? 'Part ${payment_label.toLowerCase()}' : 'Unpaid');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.hero_gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadow.lift,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(party_name,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                '${invoice.transaction_id}  ·  ${DateFormat('d MMM yyyy').format(invoice.date)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(format_dollars(invoice.total),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      fontFeatures: money_features)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: invoice.total <= 0
                      ? 1.0
                      : (paid / invoice.total).clamp(0.0, 1.0).toDouble(),
                  minHeight: 8,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text('$payment_label ${format_dollars(paid)}',
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                  Text(is_settled ? 'Settled' : 'Open ${format_dollars(open_amount)}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Items',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  StatusPill(text: status_text, color: status_color),
                ],
              ),
              const SizedBox(height: 6),
              for (final row in invoice.rows) _LineRow(row: row, snapshot: snapshot),
              const Divider(height: 28),
              _AmountRow(label: 'Amount', amount: invoice.total, is_bold: true),
              _AmountRow(label: payment_label, amount: paid, color: AppColors.brand_dark),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: _is_sharing ? null : () => _share(invoice, snapshot),
          icon: const Icon(Icons.share_rounded),
          label: Text(_is_sharing ? 'Preparing PDF...' : 'Send as PDF'),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          onPressed: open_amount <= 0 ? null : () => _record_payment(open_amount),
          icon: const Icon(Icons.payments_rounded),
          label: Text(open_amount <= 0 ? '$payment_label in full' : 'Record $payment_label'),
        ),
      ],
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.row, required this.snapshot});

  final LedgerRow row;
  final RetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final product = snapshot.product_by_sku(row.sku);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Text(product?.emoji ?? '📦', style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product?.name ?? row.sku,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('${row.qty.abs()} × ${format_dollars(row.unit_price)}',
                    style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
              ],
            ),
          ),
          Text(format_dollars(row.total_amount),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontFeatures: money_features)),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.is_bold = false,
    this.color,
  });

  final String label;
  final double amount;
  final bool is_bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: is_bold ? FontWeight.w800 : FontWeight.w600,
      fontSize: is_bold ? 17 : 14,
      fontFeatures: money_features,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(format_dollars(amount), style: style),
        ],
      ),
    );
  }
}
