# Phase 5 changes (payments + invoice PDF)

## New files
lib/models/payment.dart
lib/invoices/ (round_money, format_money, invoice_models, build_invoice_number,
  sales_rows_for_customer_on, payments_on_date, balance_before_date,
  current_balance, build_invoice_lines, build_invoice_data, pdf_table_cell,
  pdf_total_row, build_invoice_pdf, share_invoice_pdf)
lib/widgets/retailer/customer_option.dart
lib/screens/retailer/money/ (money_tab, invoice_date_field, invoice_preview_card, receive_payment_screen)
test/phase5_test.dart

## Edits to existing files (replace X with Y)
pubspec.yaml: add under dependencies
  pdf: ^3.11.1
  share_plus: ^10.1.4
retail_repository.dart: import '../models/payment.dart'; add
  Future<List<Payment>> fetch_payments();  and  Future<void> add_payment({required String customer_id, required double amount});
mock_retail_repository.dart: import payment; field `final List<Payment> _payments = [];`;
  fetch_payments(); add_payment() (rejects amount <= 0 and unknown customers)
retail_snapshot.dart: import payment; `required this.payments` + `final List<Payment> payments;`
retail_store.dart: `payments: await _repo.fetch_payments(),` in _load; new receive_payment()
retailer_home_screen.dart: import money_tab; titles + 'Money'; MoneyTab() in IndexedStack; 4th NavigationDestination

# Phase 6 changes (restyle, no prices on customer screens)
New: lib/invoices/format_dollars.dart, invoice_colors.dart, pdf_header_cell.dart
Rewritten: app_colors.dart, quantity_pill.dart, checkout_bar.dart, build_invoice_pdf.dart,
  pdf_table_cell.dart, pdf_total_row.dart
Surgical edits: app_theme.dart (poppinsTextTheme -> interTextTheme, seedColor accent),
  product_card.dart (decoration), customer_home_screen.dart (header Container, bar Positioned 0/0/0,
  grid bottom padding 110), invoice_preview_card.dart and receive_payment_screen.dart (format_dollars),
  app_config.dart (shop_name, shop_tagline)
Not done: Inter is not embedded in the PDF (it uses the built-in Helvetica), because bundling the font file needs a pubspec asset.
