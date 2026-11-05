import 'package:flutter/material.dart';

import '../../../invoices/format_dollars.dart';
import '../../../models/ledger_row.dart';
import '../../../reports/product_totals.dart';
import '../../../reports/report_type.dart';
import '../../../state/retail_snapshot.dart';
import '../../../theme/app_colors.dart';
import 'ledger_row_tile.dart';
import 'report_widgets.dart';

/// Results for the Customer and Vendor reports: one total, a per-product
/// breakdown, then the rows that make up the total.
class PartyResults extends StatelessWidget {
  const PartyResults({
    super.key,
    required this.report_type,
    required this.rows,
    required this.snapshot,
  });

  final ReportType report_type;
  final List<LedgerRow> rows;
  final RetailSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final is_customer = report_type == ReportType.customer;
    final total = rows.fold(0.0, (sum, row) => sum + row.total_amount);
    final products = product_totals(rows);
    final top_amount = products.fold(0.0, (big, t) => t.amount > big ? t.amount : big);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KpiCard(
          label: is_customer ? 'Total sales' : 'Total purchases',
          amount: total,
          accent: is_customer ? AppColors.fresh : AppColors.ink,
          icon: is_customer ? Icons.trending_up_rounded : Icons.shopping_bag_rounded,
        ),
        const SizedBox(height: 20),
        const SectionTitle('By product'),
        if (products.isEmpty) const EmptyNote(),
        for (final product in products)
          AmountRow(
            name: _product_name(product.sku),
            amount: product.amount,
            share: bar_share(product.amount, top_amount),
            color: is_customer ? AppColors.fresh : AppColors.accent,
            detail: '${product.qty} units · avg ${format_dollars(product.qty == 0 ? 0 : product.amount / product.qty)} each',
          ),
        const SizedBox(height: 20),
        SectionTitle('Rows (${rows.length})'),
        if (rows.isEmpty) const EmptyNote(),
        for (final row in rows)
          LedgerRowTile(
            row: row,
            party_name: is_customer
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
