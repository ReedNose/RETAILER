import 'package:flutter/material.dart';

import '../../../invoices/format_dollars.dart';
import '../../../models/ledger_row.dart';
import '../../../reports/product_splits.dart';
import '../../../reports/sum_amounts.dart';
import '../../../reports/totals_by_party.dart';
import '../../../state/retail_snapshot.dart';
import '../../../theme/app_colors.dart';
import 'ledger_row_tile.dart';
import 'report_widgets.dart';

/// Results for the Overall report: four KPIs, both sides of the business,
/// a per-product split, then every row behind the numbers.
class OverallResults extends StatelessWidget {
  const OverallResults({super.key, required this.rows, required this.snapshot});

  final List<LedgerRow> rows;
  final RetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final sales = sum_amounts(rows, TransactionType.sale);
    final purchases = sum_amounts(rows, TransactionType.purchase);
    final spoilage = sum_amounts(rows, TransactionType.spoilage);
    // Gross profit as the spec defines it. Stock bought but not yet sold counts as a cost.
    final profit = sales - purchases - spoilage;

    final customers = totals_by_party(
      rows: rows,
      type: TransactionType.sale,
      source: SourceType.customer,
      name_of: snapshot.customer_name,
    );
    final vendors = totals_by_party(
      rows: rows,
      type: TransactionType.purchase,
      source: SourceType.vendor,
      name_of: snapshot.vendor_name,
    );
    final splits = product_splits(rows);
    final top_customer = customers.fold(0.0, (big, t) => t.amount > big ? t.amount : big);
    final top_vendor = vendors.fold(0.0, (big, t) => t.amount > big ? t.amount : big);
    final top_product = splits.fold(0.0, (big, t) => t.sales > big ? t.sales : big);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfitHero(profit: profit, sales: sales, purchases: purchases, spoilage: spoilage),
        const SizedBox(height: 8),
        const Text(
          'Rent, wages and payments are not tracked, so these numbers mean invoiced, not cash received.',
          style: TextStyle(color: AppColors.ink_soft, fontSize: 12),
        ),
        const SizedBox(height: 20),
        const SectionTitle('By customer (sales)'),
        if (customers.isEmpty) const EmptyNote(),
        for (final total in customers)
          AmountRow(
            name: total.name,
            amount: total.amount,
            share: bar_share(total.amount, top_customer),
            color: AppColors.fresh,
          ),
        const SizedBox(height: 12),
        const SectionTitle('By vendor (purchases)'),
        if (vendors.isEmpty) const EmptyNote(),
        for (final total in vendors)
          AmountRow(
            name: total.name,
            amount: total.amount,
            share: bar_share(total.amount, top_vendor),
            color: AppColors.accent,
          ),
        const SizedBox(height: 12),
        const SectionTitle('By product'),
        if (splits.isEmpty) const EmptyNote(),
        for (final split in splits)
          AmountRow(
            name: _product_name(split.sku),
            amount: split.sales,
            share: bar_share(split.sales, top_product),
            color: AppColors.brand,
            detail: 'Purchases ${format_dollars(split.purchases)} · '
                'Spoilage ${format_dollars(split.spoilage)}',
          ),
        const SizedBox(height: 12),
        SectionTitle('Rows (${rows.length})'),
        if (rows.isEmpty) const EmptyNote(),
        for (final row in rows)
          LedgerRowTile(
            row: row,
            party_name: row.source_type == SourceType.customer
                ? snapshot.customer_name(row.source_id)
                : snapshot.vendor_name(row.source_id),
            product_name: _product_name(row.sku),
          ),
      ],
    );
  }

  String _product_name(String sku) {
    final product = snapshot.product_by_sku(sku);
    return product == null ? sku : '${product.emoji} ${product.name}';
  }
}
