import 'package:flutter_test/flutter_test.dart';
import 'package:retail_preorder_app/core/date_helpers.dart';
import 'package:retail_preorder_app/models/ledger_row.dart';
import 'package:retail_preorder_app/reports/filter_ledger_rows.dart';
import 'package:retail_preorder_app/reports/product_totals.dart';
import 'package:retail_preorder_app/reports/report_quick_ranges.dart';
import 'package:retail_preorder_app/reports/report_type.dart';
import 'package:retail_preorder_app/reports/sum_amounts.dart';
import 'package:retail_preorder_app/state/retail_providers.dart';
import 'test_support.dart';

void main() {
  test('customer report holds only customer SALE rows', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final snapshot = await container.read(retail_store_provider.future);
    final rows = filter_ledger_rows(rows: snapshot.ledger, report_type: ReportType.customer);
    final sales = snapshot.ledger.where((r) => r.transaction_type == TransactionType.sale);
    expect(rows.length, sales.length);
    expect(rows.every((r) => r.transaction_type == TransactionType.sale && r.source_type == SourceType.customer), isTrue);
    expect(sum_amounts(rows, TransactionType.sale), closeTo(7.0, 0.001));
  });

  test('vendor report holds only vendor PURCHASE rows, never spoilage', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final snapshot = await container.read(retail_store_provider.future);
    final rows = filter_ledger_rows(rows: snapshot.ledger, report_type: ReportType.vendor);
    final purchases = snapshot.ledger.where((r) => r.transaction_type == TransactionType.purchase);
    expect(rows.length, purchases.length);
    expect(rows.every((r) => r.transaction_type == TransactionType.purchase), isTrue);
  });

  test('overall profit is sales minus purchases minus spoilage', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final snapshot = await container.read(retail_store_provider.future);
    final rows = filter_ledger_rows(rows: snapshot.ledger, report_type: ReportType.overall);
    final sales = sum_amounts(rows, TransactionType.sale);
    final purchases = sum_amounts(rows, TransactionType.purchase);
    final spoilage = sum_amounts(rows, TransactionType.spoilage);
    // Seed data has one sale (7.00) and no spoilage, so profit is 7 minus all purchases.
    final profit = sales - purchases - spoilage;
    expect(spoilage, 0);
    expect(profit, closeTo(7.0 - purchases, 0.001));
  });

  test('supplier and customer together return nothing', () {
    final rows = [
      LedgerRow(
        transaction_id: 'L1',
        created_at: DateTime(2026, 11, 4),
        date: DateTime(2026, 11, 4),
        transaction_type: TransactionType.sale,
        source_type: SourceType.customer,
        source_id: 'C001',
        batch_id: 'ML_2402',
        qty: -2,
        unit_price: 3.5,
        total_amount: 7,
      ),
    ];
    final both = filter_ledger_rows(
      rows: rows,
      report_type: ReportType.overall,
      customer_id: 'C001',
      vendor_id: 'V001',
    );
    expect(both, isEmpty);
  });

  test('date range is inclusive and yesterday excludes today-only sales', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final snapshot = await container.read(retail_store_provider.future);
    final today = date_only(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final customer = filter_ledger_rows(
      rows: snapshot.ledger,
      report_type: ReportType.customer,
      start_date: yesterday,
      end_date: yesterday,
    );
    expect(customer, isEmpty);
    final vendor = filter_ledger_rows(
      rows: snapshot.ledger,
      report_type: ReportType.vendor,
      start_date: yesterday,
      end_date: yesterday,
    );
    expect(vendor, isNotEmpty);
  });

  test('product breakdown shows positive qty for sales', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final snapshot = await container.read(retail_store_provider.future);
    final rows = filter_ledger_rows(
      rows: snapshot.ledger,
      report_type: ReportType.customer,
      sku: 'ML',
    );
    final totals = product_totals(rows);
    expect(totals.length, 1);
    expect(totals.first.qty, 2);
    expect(totals.first.amount, closeTo(7.0, 0.001));
  });

  test('batch filter matches one batch exactly', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final snapshot = await container.read(retail_store_provider.future);
    final rows = filter_ledger_rows(
      rows: snapshot.ledger,
      report_type: ReportType.overall,
      batch_id: 'ML_2402',
    );
    expect(rows, isNotEmpty);
    expect(rows.every((r) => r.batch_id == 'ML_2402'), isTrue);
  });

  test('quick ranges: this month starts on the 1st and ends on the last day', () {
    final span = quick_range_this_month(DateTime(2026, 11, 4, 15));
    expect(span.start, DateTime(2026, 11, 1));
    expect(span.end, DateTime(2026, 11, 30));
  });

  test('quick ranges: this week runs Monday to Sunday', () {
    final span = quick_range_this_week(DateTime(2026, 11, 4)); // a Wednesday
    expect(span.start, DateTime(2026, 11, 2));
    expect(span.end, DateTime(2026, 11, 8));
  });
}
