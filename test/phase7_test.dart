import 'package:flutter_test/flutter_test.dart';
import 'package:retail_preorder_app/invoices/build_ledger_invoice_pdf.dart';
import 'package:retail_preorder_app/invoices/group_ledger_invoices.dart';
import 'package:retail_preorder_app/invoices/invoice_search.dart';
import 'package:retail_preorder_app/invoices/ledger_invoice.dart';
import 'package:retail_preorder_app/models/ledger_row.dart';
import 'package:retail_preorder_app/models/pickup_allocation.dart';
import 'package:retail_preorder_app/models/purchase_line.dart';
import 'package:retail_preorder_app/state/retail_providers.dart';
import 'test_support.dart';

LedgerRow _row(String id, DateTime day, TransactionType type, String party, String batch,
        int qty, double price) =>
    LedgerRow(
      transaction_id: id,
      created_at: day,
      date: day,
      transaction_type: type,
      source_type: type == TransactionType.sale ? SourceType.customer : SourceType.vendor,
      source_id: party,
      batch_id: batch,
      qty: type == TransactionType.purchase ? qty : -qty,
      unit_price: price,
      total_amount: qty * price,
    );

void main() {
  final d1 = DateTime(2026, 11, 3);
  final d2 = DateTime(2026, 11, 4);

  final ledger = [
    _row('T1', d1, TransactionType.purchase, 'V001', 'ML_1', 10, 2.0),
    _row('T1', d1, TransactionType.purchase, 'V001', 'EG_1', 5, 3.0),
    _row('T2', d2, TransactionType.purchase, 'V002', 'BR_1', 4, 3.5),
    _row('T3', d2, TransactionType.sale, 'C001', 'ML_1', 2, 3.5),
    _row('T3', d2, TransactionType.sale, 'C001', 'EG_1', 1, 5.0),
    _row('T4', d2, TransactionType.spoilage, 'V001', 'ML_1', 1, 2.0),
  ];

  test('rows with the same transaction_id form one invoice', () {
    final purchases = group_ledger_invoices(ledger, TransactionType.purchase);
    expect(purchases.length, 2);
    final t1 = purchases.firstWhere((i) => i.transaction_id == 'T1');
    expect(t1.rows.length, 2);
    expect(t1.total, closeTo(35.0, 0.001));
    expect(t1.party_id, 'V001');
  });

  test('sales and purchases never mix, and spoilage is left out', () {
    final sales = group_ledger_invoices(ledger, TransactionType.sale);
    expect(sales.single.transaction_id, 'T3');
    expect(sales.single.total, closeTo(12.0, 0.001));
    expect(sales.single.total_qty, 3);
  });

  test('newest invoice comes first', () {
    final purchases = group_ledger_invoices(ledger, TransactionType.purchase);
    expect(purchases.first.transaction_id, 'T2');
  });

  test('seed data has a multi-line purchase invoice', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final snapshot = await container.read(retail_store_provider.future);
    final purchases = group_ledger_invoices(snapshot.ledger, TransactionType.purchase);
    expect(purchases.any((i) => i.rows.length > 1), isTrue);
  });

  test('one pickup with two batches makes one sales invoice', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final before = await container.read(retail_store_provider.future);
    final sales_before = group_ledger_invoices(before.ledger, TransactionType.sale).length;

    await container.read(retail_store_provider.notifier).complete_pickup(
      customer_id: 'C002',
      pickup_date: DateTime.now(),
      allocations: [
        PickupAllocation(batch_id: 'ML_2402', qty: 1, unit_price: 3.5),
        PickupAllocation(batch_id: 'ML_2401', qty: 1, unit_price: 3.5),
      ],
    );

    final after = await container.read(retail_store_provider.future);
    final sales = group_ledger_invoices(after.ledger, TransactionType.sale);
    expect(sales.length, sales_before + 1);
    // Find the new invoice by party: seed sales belong to C001, this one is C002.
    final pickup_invoice = sales.firstWhere((i) => i.party_id == 'C002');
    expect(pickup_invoice.rows.length, 2);
  });

  test('paying an invoice is capped at what is open', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final snapshot = await container.read(retail_store_provider.future);
    final sale = group_ledger_invoices(snapshot.ledger, TransactionType.sale).first;
    final store = container.read(retail_store_provider.notifier);

    await store.record_invoice_payment(transaction_id: sale.transaction_id, amount: 2.0);
    final after = await container.read(retail_store_provider.future);
    expect(after.paid_on_invoice(sale.transaction_id), closeTo(2.0, 0.001));
    // A sales receipt also lowers the customer's balance (a Payment row).
    expect(after.payments.length, snapshot.payments.length + 1);

    expect(
      () => store.record_invoice_payment(
          transaction_id: sale.transaction_id, amount: sale.total),
      throwsStateError,
    );
  });

  test('a purchase payment does not create a customer payment', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final snapshot = await container.read(retail_store_provider.future);
    final purchase = group_ledger_invoices(snapshot.ledger, TransactionType.purchase).first;
    await container
        .read(retail_store_provider.notifier)
        .record_invoice_payment(transaction_id: purchase.transaction_id, amount: 1.0);
    final after = await container.read(retail_store_provider.future);
    expect(after.paid_on_invoice(purchase.transaction_id), closeTo(1.0, 0.001));
    expect(after.payments.length, snapshot.payments.length);
  });

  test('the invoice PDF builds real PDF bytes', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final snapshot = await container.read(retail_store_provider.future);
    final purchase = group_ledger_invoices(snapshot.ledger, TransactionType.purchase).first;
    final bytes = await build_ledger_invoice_pdf(purchase, snapshot);
    expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
  });

  test('a purchase invoice with two lines is one invoice with two new batches', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final store = container.read(retail_store_provider.notifier);
    await container.read(retail_store_provider.future);

    final id = await store.save_purchase_invoice(
      vendor_id: 'V001',
      lines: const [
        PurchaseLine(sku: 'ML', qty: 6, unit_cost: 2.0),
        PurchaseLine(sku: 'EG', qty: 4, unit_cost: 3.0),
      ],
      paid: 10.0,
    );

    final snapshot = await container.read(retail_store_provider.future);
    final invoice = group_ledger_invoices(snapshot.ledger, TransactionType.purchase)
        .firstWhere((i) => i.transaction_id == id);
    expect(invoice.rows.length, 2);
    expect(invoice.rows.map((r) => r.batch_id).toSet().length, 2);
    expect(invoice.total, closeTo(24.0, 0.001));
    expect(snapshot.paid_on_invoice(id), closeTo(10.0, 0.001));
  });

  test('a sales invoice with two lines is one invoice and takes stock', () async {
    final container = demo_container();
    addTearDown(container.dispose);
    final store = container.read(retail_store_provider.notifier);
    await container.read(retail_store_provider.future);

    final id = await store.save_sales_invoice(
      customer_id: 'C003',
      lines: const [
        PickupAllocation(batch_id: 'ML_2401', qty: 2, unit_price: 3.5),
        PickupAllocation(batch_id: 'EG_2403', qty: 1, unit_price: 5.0),
      ],
      received: 4.0,
    );

    final snapshot = await container.read(retail_store_provider.future);
    final invoice = group_ledger_invoices(snapshot.ledger, TransactionType.sale)
        .firstWhere((i) => i.transaction_id == id);
    expect(invoice.rows.length, 2);
    expect(invoice.total, closeTo(12.0, 0.001));
    expect(snapshot.paid_on_invoice(id), closeTo(4.0, 0.001));
    expect(snapshot.batch_by_id('ML_2401')!.current_qty, 6);
  });

  test('open amount is the total minus paid, never below zero', () {
    final invoice = _invoice(total: 31.70);
    expect(open_amount_of(invoice, 0), closeTo(31.70, 0.001));
    expect(open_amount_of(invoice, 11.70), closeTo(20.0, 0.001));
    expect(open_amount_of(invoice, 40), 0);
  });

  test('search matches invoice number or party name, ignoring case', () {
    final invoice = _invoice(total: 10, id: 'TRX-M3K9Q2');
    expect(invoice_matches_query(invoice, 'Gulf Fresh Produce', ''), isTrue);
    expect(invoice_matches_query(invoice, 'Gulf Fresh Produce', 'm3k9'), isTrue);
    expect(invoice_matches_query(invoice, 'Gulf Fresh Produce', 'GULF'), isTrue);
    expect(invoice_matches_query(invoice, 'Gulf Fresh Produce', 'sahara'), isFalse);
  });
}

LedgerInvoice _invoice({required double total, String id = 'TRX-1'}) => LedgerInvoice(
      transaction_id: id,
      date: DateTime(2026, 11, 4),
      type: TransactionType.purchase,
      party_id: 'V001',
      rows: const [],
      total: total,
    );

