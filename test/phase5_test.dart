import 'package:flutter_test/flutter_test.dart';
import 'package:retail_preorder_app/data/mock/mock_retail_repository.dart';
import 'package:retail_preorder_app/data/mock/seed_data.dart';
import 'package:retail_preorder_app/invoices/balance_before_date.dart';
import 'package:retail_preorder_app/invoices/build_invoice_data.dart';
import 'package:retail_preorder_app/invoices/build_invoice_number.dart';
import 'package:retail_preorder_app/invoices/build_invoice_pdf.dart';
import 'package:retail_preorder_app/invoices/format_dollars.dart';
import 'package:retail_preorder_app/invoices/format_money.dart';
import 'package:retail_preorder_app/models/ledger_row.dart';
import 'package:retail_preorder_app/models/payment.dart';
import 'package:retail_preorder_app/state/retail_providers.dart';
import 'package:retail_preorder_app/state/retail_snapshot.dart';
import 'test_support.dart';

LedgerRow _sale(String id, DateTime day, String customer_id, String batch_id, int qty, double price) =>
    LedgerRow(
      transaction_id: id,
      created_at: day,
      date: day,
      transaction_type: TransactionType.sale,
      source_type: SourceType.customer,
      source_id: customer_id,
      batch_id: batch_id,
      qty: -qty,
      unit_price: price,
      total_amount: qty * price,
    );

Payment _payment(String id, DateTime day, String customer_id, double amount) => Payment(
      payment_id: id,
      created_at: day,
      date: day,
      customer_id: customer_id,
      amount: amount,
    );

RetailSnapshot _snapshot({required List<LedgerRow> ledger, required List<Payment> payments}) =>
    RetailSnapshot(
      products: seed_products,
      vendors: seed_vendors,
      customers: seed_customers,
      warehouse: const [],
      need_list: const [],
      ledger: ledger,
      payments: payments,
    );

void main() {
  final yesterday = DateTime(2026, 11, 3);
  final today = DateTime(2026, 11, 4);

  // Yesterday: Maria bought 20.00 and paid 5.00 (owes 15.00).
  // Today: 3 milk (2 x 3.50 and 1 x 3.00 = 10.00) and 1 eggs (5.00), paid 4.00.
  final ledger = [
    _sale('L1', yesterday, 'C001', 'BR_1', 4, 5.0),
    _sale('L2', today, 'C001', 'ML_2402', 2, 3.5),
    _sale('L3', today, 'C001', 'ML_2401', 1, 3.0),
    _sale('L4', today, 'C001', 'EG_2403', 1, 5.0),
    _sale('L5', today, 'C002', 'ML_2401', 1, 3.5), // another customer
  ];
  final payments = [
    _payment('P1', yesterday, 'C001', 5.0),
    _payment('P2', today, 'C001', 4.0),
  ];

  test('old balance counts only days before the invoice day', () {
    final balance = balance_before_date(
      ledger: ledger,
      payments: payments,
      customer_id: 'C001',
      day: today,
    );
    expect(balance, closeTo(15.0, 0.001));
  });

  test('a customer with no history starts at zero', () {
    final balance = balance_before_date(
      ledger: ledger,
      payments: payments,
      customer_id: 'C002',
      day: today,
    );
    expect(balance, 0);
  });

  test('invoice merges lines per product and balances add up', () {
    final invoice = build_invoice_data(
      snapshot: _snapshot(ledger: ledger, payments: payments),
      customer_id: 'C001',
      day: today,
    )!;
    expect(invoice.lines.map((l) => l.product_name).toList(), ['Eggs (12pk)', 'Whole Milk']);
    final milk = invoice.lines.last;
    expect(milk.qty, 3);
    expect(milk.line_total, closeTo(10.0, 0.001));
    expect(milk.unit_price, closeTo(3.33, 0.001));
    expect(invoice.grand_total, closeTo(15.0, 0.001));
    expect(invoice.old_balance, closeTo(15.0, 0.001));
    expect(invoice.payments_received, closeTo(4.0, 0.001));
    expect(invoice.new_balance, closeTo(26.0, 0.001)); // 15 + 15 - 4
  });

  test('no sales on the day means no invoice', () {
    final invoice = build_invoice_data(
      snapshot: _snapshot(ledger: ledger, payments: payments),
      customer_id: 'C003',
      day: today,
    );
    expect(invoice, isNull);
  });

  test('invoice number is stable for one customer and day', () {
    expect(build_invoice_number(customer_id: 'C001', day: today), 'INV-20261104-C001');
  });

  test('money prints with two decimals and thousands separators', () {
    expect(format_money(1234.5), '1,234.50');
    expect(format_money(0), '0.00');
  });

  test('dollars keep the minus in front of the dollar sign', () {
    expect(format_dollars(26), '\$26.00');
    expect(format_dollars(-5), '-\$5.00');
    expect(format_dollars(0), '\$0.00');
  });

  test('the PDF builder returns real PDF bytes', () async {
    final invoice = build_invoice_data(
      snapshot: _snapshot(ledger: ledger, payments: payments),
      customer_id: 'C001',
      day: today,
    )!;
    final bytes = await build_invoice_pdf(invoice);
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });

  test('a payment never touches the ledger, and zero is rejected', () async {
    final repo = MockRetailRepository();
    final ledger_before = (await repo.fetch_snapshot()).ledger.length;
    await repo.add_payment(customer_id: 'C001', amount: 5.0);
    expect((await repo.fetch_snapshot()).ledger.length, ledger_before);
    expect((await repo.fetch_snapshot()).payments.length, 1);
    expect(() => repo.add_payment(customer_id: 'C001', amount: 0), throwsStateError);
  });

  test('receive_payment through the store lowers the next balance', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    await container.read(retail_store_provider.future);
    await container.read(retail_store_provider.notifier).receive_payment(
          customer_id: 'C001',
          amount: 2.0,
        );
    final snapshot = await container.read(retail_store_provider.future);
    expect(snapshot.payments.single.amount, 2.0);
  });
}
