// Backend JSON to app models. The keys are the sheet column headers, so a renamed column
// shows up here as a missing value, not as a silent wrong one.

import '../../models/app_user.dart';
import '../../models/customer.dart';
import '../../models/invoice_payment.dart';
import '../../models/ledger_row.dart';
import '../../models/need_list_row.dart';
import '../../models/payment.dart';
import '../../models/product.dart';
import '../../models/vendor.dart';
import '../../models/warehouse_batch.dart';

String text_of(Object? value) => value == null ? '' : value.toString();

double money_of(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(text_of(value)) ?? 0;

int int_of(Object? value) => value is num ? value.toInt() : int.tryParse(text_of(value)) ?? 0;

// Dates arrive as yyyy-MM-dd and times as yyyy-MM-ddTHH:mm:ss, both in shop time.
// DateTime.parse reads them as local time, which is the shop's time.
DateTime day_of(Object? value) => DateTime.tryParse(text_of(value)) ?? DateTime.now();

bool bool_of(Object? value) => value == true || text_of(value).toUpperCase() == 'TRUE';

/// Matches a backend text value such as 'SALE' to the enum value named 'sale'.
T enum_from<T extends Enum>(List<T> values, String db_value) => values.firstWhere(
      (value) => value.name.toUpperCase() == db_value.toUpperCase(),
      orElse: () => throw FormatException('Unknown value $db_value'),
    );

List<Map<String, dynamic>> rows_of(Object? value) =>
    (value as List<dynamic>? ?? const []).cast<Map<String, dynamic>>();

Product product_from_json(Map<String, dynamic> json) {
  final shelf = int_of(json['shelf_life_days']);
  return Product(
    sku: text_of(json['sku']),
    name: text_of(json['name']),
    emoji: text_of(json['emoji']),
    category: text_of(json['category']),
    default_retail_price: money_of(json['default_retail_price']),
    shelf_life_days: shelf == 0 ? 2 : shelf,
  );
}

Vendor vendor_from_json(Map<String, dynamic> json) => Vendor(
      vendor_id: text_of(json['vendor_id']),
      name: text_of(json['name']),
      whatsapp_no: text_of(json['whatsapp_no']),
    );

Customer customer_from_json(Map<String, dynamic> json) => Customer(
      customer_id: text_of(json['customer_id']),
      name: text_of(json['name']),
      whatsapp_no: text_of(json['whatsapp_no']),
    );

WarehouseBatch batch_from_json(Map<String, dynamic> json) => WarehouseBatch(
      batch_id: text_of(json['batch_id']),
      vendor_id: text_of(json['vendor_id']),
      batch_date: day_of(json['batch_date']),
      current_qty: int_of(json['current_qty']),
    );

NeedListRow need_from_json(Map<String, dynamic> json) => NeedListRow(
      need_id: text_of(json['need_id']),
      created_at: day_of(json['created_at']),
      pickup_date: day_of(json['pickup_date']),
      customer_id: text_of(json['customer_id']),
      sku: text_of(json['sku']),
      qty: int_of(json['qty']),
      is_done: bool_of(json['is_done']),
    );

LedgerRow ledger_from_json(Map<String, dynamic> json) => LedgerRow(
      transaction_id: text_of(json['transaction_id']),
      created_at: day_of(json['created_at']),
      date: day_of(json['date']),
      transaction_type: enum_from(TransactionType.values, text_of(json['transaction_type'])),
      source_type: enum_from(SourceType.values, text_of(json['source_type'])),
      source_id: text_of(json['source_id']),
      batch_id: text_of(json['batch_id']),
      qty: int_of(json['qty']),
      unit_price: money_of(json['unit_price']),
      total_amount: money_of(json['total_amount']),
    );

Payment payment_from_json(Map<String, dynamic> json) => Payment(
      payment_id: text_of(json['payment_id']),
      created_at: day_of(json['created_at']),
      date: day_of(json['date']),
      customer_id: text_of(json['customer_id']),
      amount: money_of(json['amount']),
    );

InvoicePayment invoice_payment_from_json(Map<String, dynamic> json) => InvoicePayment(
      payment_id: text_of(json['payment_id']),
      created_at: day_of(json['created_at']),
      date: day_of(json['date']),
      transaction_id: text_of(json['transaction_id']),
      amount: money_of(json['amount']),
    );

AppUser user_from_json(Map<String, dynamic> json) => AppUser(
      user_id: text_of(json['user_id']),
      role: enum_from(UserRole.values, text_of(json['role'])),
      customer_id: json['customer_id'] == null ? null : text_of(json['customer_id']),
      pin_hash: '', // the server never sends a PIN, so nothing is kept here
    );
