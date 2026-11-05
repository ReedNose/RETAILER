# Phase 7 changes (Purchase and Sales invoices)

An invoice = every ledger row that shares one `transaction_id` (TRX id).

New: lib/core/new_transaction_id.dart, lib/invoices/ledger_invoice.dart,
  lib/invoices/group_ledger_invoices.dart,
  lib/screens/retailer/invoices/ (invoices_tab, invoice_list, invoice_detail_screen),
  test/phase7_test.dart
Edits: retailer_home_screen.dart (5th destination "Invoices", with Purchases / Sales tabs inside),
  retail_repository.dart + mock (sell_from_batch takes optional transaction_id),
  retail_store.dart (complete_pickup gives all rows of one pickup the same id),
  seed_data.dart (same vendor + same day purchases share one id; seed sale id TRX-S001)
(Done later: PDF in 7b; multi-line purchase save in 7e.)

## Phase 7b (open an invoice, send PDF, paid / received)
New: lib/models/invoice_payment.dart, lib/invoices/build_ledger_invoice_pdf.dart,
  lib/invoices/share_ledger_invoice_pdf.dart
Edits: retail_repository + mock (fetch_invoice_payments, add_invoice_payment: capped at the open
  amount; a sales receipt also adds a customer Payment so balances stay right),
  retail_snapshot (invoice_payments, paid_on_invoice), retail_store (record_invoice_payment),
  invoice_list (name, date, amount, status), invoice_detail_screen (lines, Amount, Paid/Received,
  Send as PDF, Record Paid/Received)

Phase 7c: invoice lines now show unit price (PDF column + detail screen). Preorder screens stay price-free.

Phase 7d: prices back everywhere except the customer preorder screens.
Edits: ledger_row_tile, report_widgets, party_results (avg price per product), overall_results,
  invoice_preview_card (unit price on each line), inventory_batch_card (selling price).
Report amounts now print with a dollar sign. Forms already had price fields (pickup, walk-in, add stock).

Phase 7e: invoice entry (multi-item purchase and sales invoices)
New: lib/models/purchase_line.dart, lib/screens/retailer/invoices/entry/
  (invoice_entry_screen, entry_line, entry_line_card, entry_qty_stepper, entry_total_bar)
Edits: invoices_tab (green New purchase / New sale button), invoice_list (bottom padding),
  retail_repository + mock (add_stock takes optional transaction_id),
  retail_store (save_purchase_invoice, save_sales_invoice: one shared transaction_id,
  batch ids made by the app, optional paid/received now)

Phase 7f: Invoices list usability
Edits: lib/screens/retailer/invoices/invoice_list.dart (now a StatefulWidget)
  - Summary card at the top of each tab: money still open (to pay vendors / to receive from customers)
    and how many invoices are open
  - Search box filters by party name or invoice number (clear button included)
  - Open amount per invoice = total minus paid, never below zero
Not compiled: no Flutter SDK in the build sandbox. Run flutter analyze and flutter test.
Known gap (not changed): save_purchase_invoice and save_sales_invoice write one row group at a time,
  so a failure partway leaves some rows saved under the transaction id. Needs a transactional
  repository write (or a rollback step) before real data uses it.
