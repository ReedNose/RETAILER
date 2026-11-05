import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/batch_freshness.dart';
import '../../../../core/date_helpers.dart';
import '../../../../core/input_parsing.dart';
import '../../../../invoices/format_dollars.dart';
import '../../../../invoices/round_money.dart';
import '../../../../models/ledger_row.dart';
import '../../../../models/pickup_allocation.dart';
import '../../../../models/purchase_line.dart';
import '../../../../state/retail_providers.dart';
import '../../../../state/retail_snapshot.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/retailer/batch_option.dart';
import '../../../../widgets/retailer/customer_option.dart';
import '../../../../widgets/retailer/product_option.dart';
import '../../../../widgets/shared/searchable_dropdown.dart';
import '../../../../widgets/shared/searchable_option.dart';
import '../../../../widgets/shared/searchable_sheet.dart';
import 'entry_line.dart';
import 'entry_line_card.dart';
import 'entry_total_bar.dart';

/// One screen for both kinds of invoice entry. [type] is purchase (from a
/// vendor) or sale (to a customer). Every item saved here shares one
/// transaction_id, so it shows up as one invoice in the Invoices tab.
class InvoiceEntryScreen extends ConsumerStatefulWidget {
  const InvoiceEntryScreen({super.key, required this.type});

  final TransactionType type;

  @override
  ConsumerState<InvoiceEntryScreen> createState() => _InvoiceEntryScreenState();
}

class _InvoiceEntryScreenState extends ConsumerState<InvoiceEntryScreen> {
  final List<EntryLine> _lines = [];
  final _payment_controller = TextEditingController();
  String? _party_id;
  bool _is_saving = false;

  bool get _is_purchase => widget.type == TransactionType.purchase;

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    _payment_controller.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  double get _total => round_money(_lines.fold(0.0, (sum, l) => sum + l.amount));

  List<SearchableOption<String>> _party_options(RetailSnapshot snapshot) => _is_purchase
      ? [
          for (final vendor in snapshot.vendors)
            SearchableOption<String>(value: vendor.vendor_id, label: vendor.name),
        ]
      : customer_options(snapshot);

  /// Latest purchase cost of a product, so the retailer rarely retypes it.
  double? _last_cost(RetailSnapshot snapshot, String sku) {
    LedgerRow? latest;
    for (final row in snapshot.ledger) {
      if (row.transaction_type != TransactionType.purchase || row.sku != sku) continue;
      if (latest == null || !row.date.isBefore(latest.date)) latest = row;
    }
    return latest?.unit_price;
  }

  EntryLine _new_line(RetailSnapshot snapshot, String sku) {
    if (_is_purchase) {
      return EntryLine(sku: sku, price: _last_cost(snapshot, sku) ?? 0);
    }
    final batches = snapshot.batches_for_sku(sku); // oldest (Day 2) first
    return EntryLine(
      sku: sku,
      batch_id: batches.isEmpty ? null : batches.first.batch_id,
      price: snapshot.product_by_sku(sku)?.default_retail_price ?? 0,
    );
  }

  Future<String?> _choose_product(RetailSnapshot snapshot) async {
    final options =
        _is_purchase ? product_options_all(snapshot) : product_options_in_stock(snapshot);
    if (options.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nothing in stock to sell')));
      return null;
    }
    final choice = await show_searchable_sheet<String>(
      context: context,
      title: 'Choose product',
      options: options,
    );
    return choice?.value;
  }

  Future<void> _add_item(RetailSnapshot snapshot) async {
    final sku = await _choose_product(snapshot);
    if (sku == null || !mounted) return;
    setState(() => _lines.add(_new_line(snapshot, sku)));
  }

  Future<void> _change_product(RetailSnapshot snapshot, EntryLine line) async {
    final sku = await _choose_product(snapshot);
    if (sku == null || !mounted || sku == line.sku) return;
    final fresh = _new_line(snapshot, sku);
    setState(() {
      line.sku = sku;
      line.batch_id = fresh.batch_id;
      line.price_controller.text = fresh.price_controller.text;
    });
    fresh.dispose();
  }

  Future<void> _pick_batch(RetailSnapshot snapshot, EntryLine line) async {
    final product = snapshot.product_by_sku(line.sku);
    final today = date_only(DateTime.now());
    final options = [
      for (final batch in snapshot.batches_for_sku(line.sku))
        batch_option(batch: batch, product: product, today: today),
    ];
    final choice = await show_searchable_sheet<String>(
      context: context,
      title: 'Choose batch',
      options: options,
    );
    if (choice == null || !mounted) return;
    setState(() => line.batch_id = choice.value);
  }

  /// Returns what is wrong, or null when the invoice can be saved.
  String? _problem(RetailSnapshot snapshot) {
    if (_party_id == null) return _is_purchase ? 'Choose a vendor first' : 'Choose a customer first';
    if (_lines.isEmpty) return 'Add at least one item';
    for (final line in _lines) {
      if (line.qty <= 0) return 'Every item needs a quantity';
    }
    if (!_is_purchase) {
      final wanted = <String, int>{};
      for (final line in _lines) {
        final batch_id = line.batch_id;
        if (batch_id == null) return 'Choose a batch for every item';
        wanted[batch_id] = (wanted[batch_id] ?? 0) + line.qty;
      }
      for (final entry in wanted.entries) {
        final left = snapshot.batch_by_id(entry.key)?.current_qty ?? 0;
        if (entry.value > left) return 'Only $left left in ${entry.key}';
      }
    }
    final paid = parse_money(_payment_controller.text) ?? 0;
    if (paid > _total + 0.005) return 'That is more than the invoice amount';
    return null;
  }

  Future<void> _save(RetailSnapshot snapshot) async {
    final messenger = ScaffoldMessenger.of(context);
    final problem = _problem(snapshot);
    if (problem != null) {
      messenger.showSnackBar(SnackBar(content: Text(problem)));
      return;
    }
    final party_id = _party_id!;
    final money = parse_money(_payment_controller.text) ?? 0;
    final navigator = Navigator.of(context);
    final store = ref.read(retail_store_provider.notifier);

    setState(() => _is_saving = true);
    try {
      final transaction_id = _is_purchase
          ? await store.save_purchase_invoice(
              vendor_id: party_id,
              lines: [
                for (final l in _lines)
                  PurchaseLine(sku: l.sku, qty: l.qty, unit_cost: l.price),
              ],
              paid: money,
            )
          : await store.save_sales_invoice(
              customer_id: party_id,
              lines: [
                for (final l in _lines)
                  PickupAllocation(batch_id: l.batch_id!, qty: l.qty, unit_price: l.price),
              ],
              received: money,
            );
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Invoice $transaction_id saved'),
      ));
    } catch (error) {
      if (mounted) setState(() => _is_saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(retail_store_provider).valueOrNull;
    final title = _is_purchase ? 'New purchase invoice' : 'New sales invoice';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
      ),
      body: snapshot == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _form(snapshot)),
                EntryTotalBar(
                  total: _total,
                  payment_label: _is_purchase ? 'Paid now' : 'Received now',
                  payment_controller: _payment_controller,
                  save_label: _is_purchase ? 'Save purchase' : 'Save sale',
                  is_saving: _is_saving,
                  on_changed: _refresh,
                  on_save: () => _save(snapshot),
                ),
              ],
            ),
    );
  }

  Widget _form(RetailSnapshot snapshot) {
    final today = date_only(DateTime.now());
    final options = _party_options(snapshot);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        SearchableDropdown<String>(
          label: _is_purchase ? 'Vendor' : 'Customer',
          sheet_title: _is_purchase ? 'Choose vendor' : 'Choose customer',
          options: options,
          selected: option_for(options, _party_id),
          on_changed: (value) => setState(() => _party_id = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InfoChip(
              icon: Icons.calendar_today_rounded,
              text: 'Today · ${DateFormat('d MMM yyyy').format(today)}',
            ),
            const _InfoChip(icon: Icons.tag_rounded, text: 'Number made on save'),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            const Text('Items', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent_tint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${_lines.length}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  )),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_lines.isEmpty) _empty_state(),
        for (final line in _lines) _line_card(snapshot, line, today),
        FilledButton.icon(
          onPressed: () => _add_item(snapshot),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add item',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent_tint,
            foregroundColor: AppColors.accent,
            elevation: 0,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _line_card(RetailSnapshot snapshot, EntryLine line, DateTime today) {
    final product = snapshot.product_by_sku(line.sku);
    String? batch_label;
    var batch_is_priority = false;
    if (!_is_purchase) {
      final batch = line.batch_id == null ? null : snapshot.batch_by_id(line.batch_id!);
      if (batch == null) {
        batch_label = 'Choose batch';
      } else {
        batch_label = '${batch.batch_id} · ${batch.current_qty} left';
        batch_is_priority = is_priority_batch(
          batch_date: batch.batch_date,
          shelf_life_days: product?.shelf_life_days ?? 2,
          today: today,
        );
      }
    }
    final last_cost = _last_cost(snapshot, line.sku);

    return EntryLineCard(
      key: line.key,
      line: line,
      product: product,
      price_label: _is_purchase ? 'Unit cost' : 'Unit price',
      hint: _is_purchase
          ? (last_cost == null ? 'New batch on save' : 'Last cost ${format_dollars(last_cost)}')
          : 'Retail ${format_dollars(product?.default_retail_price ?? 0)}',
      batch_label: batch_label,
      batch_is_priority: batch_is_priority,
      on_pick_batch: _is_purchase ? null : () => _pick_batch(snapshot, line),
      on_pick_product: () => _change_product(snapshot, line),
      on_remove: () => setState(() {
        _lines.remove(line);
        WidgetsBinding.instance.addPostFrameCallback((_) => line.dispose());
      }),
      on_changed: _refresh,
    );
  }

  Widget _empty_state() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: const Column(
          children: [
            Icon(Icons.shopping_basket_outlined, size: 36, color: AppColors.ink_soft),
            SizedBox(height: 10),
            Text('No items yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            SizedBox(height: 2),
            Text('Tap Add item to start the invoice.',
                style: TextStyle(color: AppColors.ink_soft, fontSize: 13)),
          ],
        ),
      );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.ink_soft),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: AppColors.ink_soft, fontSize: 12.5)),
        ],
      ),
    );
  }
}
