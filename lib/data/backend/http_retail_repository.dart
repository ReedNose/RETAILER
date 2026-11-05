import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/pickup_allocation.dart';
import '../../models/purchase_line.dart';
import '../../models/warehouse_batch.dart';
import '../../state/retail_snapshot.dart';
import '../retail_repository.dart';
import 'backend_client.dart';
import 'backend_mappers.dart';

/// Talks to the Apps Script backend. Each method is one call to the backend's action of the
/// same meaning, so a whole invoice is saved in one request.
class HttpRetailRepository implements RetailRepository {
  HttpRetailRepository({required String backend_url})
      : _backend = BackendClient(base_url: backend_url);

  final BackendClient _backend;
  UserRole? _role;

  @override
  Future<AppUser> sign_in(String pin) async {
    _backend.user_id = null;
    _backend.pin = pin;
    try {
      final data = await _backend.call('sign_in') as Map<String, dynamic>;
      final user = user_from_json(data);
      _backend.user_id = user.user_id;
      _role = user.role;
      return user;
    } on BackendException {
      _backend.pin = null;
      throw const WrongPin();
    } catch (_) {
      _backend.pin = null;
      rethrow;
    }
  }

  @override
  void sign_out() {
    _backend.user_id = null;
    _backend.pin = null;
    _role = null;
  }

  @override
  Future<RetailSnapshot> fetch_snapshot() async {
    if (_role == UserRole.customer) return _customer_snapshot();

    final data = await _backend.call('read_all') as Map<String, dynamic>;
    return RetailSnapshot(
      products: rows_of(data['products']).map(product_from_json).toList(),
      vendors: rows_of(data['vendors']).map(vendor_from_json).toList(),
      customers: rows_of(data['customers']).map(customer_from_json).toList(),
      warehouse: rows_of(data['warehouse']).map(batch_from_json).toList(),
      need_list: rows_of(data['need_list']).map(need_from_json).toList(),
      ledger: rows_of(data['ledger']).map(ledger_from_json).toList(),
      payments: rows_of(data['payments']).map(payment_from_json).toList(),
      invoice_payments: rows_of(data['invoice_payments']).map(invoice_payment_from_json).toList(),
    );
  }

  /// Customers get products without prices, total stock per product, and their own list.
  Future<RetailSnapshot> _customer_snapshot() async {
    final data = await _backend.call('read_customer_view') as Map<String, dynamic>;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final products = rows_of(data['products']);
    return RetailSnapshot(
      products: [
        for (final json in products) product_from_json({...json, 'default_retail_price': 0}),
      ],
      vendors: const [],
      customers: [
        if (data['customer'] is Map<String, dynamic>)
          customer_from_json({
            ...(data['customer'] as Map<String, dynamic>),
            'whatsapp_no': '',
          }),
      ],
      // One row per product holding its total. The customer screens only add stock up per
      // product, so the batch split is not needed and is not sent.
      warehouse: [
        for (final json in products)
          WarehouseBatch(
            batch_id: '${text_of(json['sku'])}_TOTAL',
            vendor_id: '',
            batch_date: today,
            current_qty: int_of(json['total_stock']),
          ),
      ],
      need_list: rows_of(data['need_list']).map(need_from_json).toList(),
      ledger: const [],
      payments: const [],
      invoice_payments: const [],
    );
  }

  @override
  Future<void> add_need_list_rows({
    required String customer_id,
    required DateTime pickup_date,
    required Map<String, int> qty_by_sku,
  }) async {
    await _backend.call('add_need_list_rows', {
      'customer_id': customer_id,
      'pickup_date': _day_text(pickup_date),
      'qty_by_sku': qty_by_sku,
    });
  }

  @override
  Future<void> mark_need_list_done({
    required String customer_id,
    required DateTime pickup_date,
  }) async {
    await _backend.call('mark_need_list_done', {
      'customer_id': customer_id,
      'pickup_date': _day_text(pickup_date),
    });
  }

  @override
  Future<String> save_purchase_invoice({
    required String vendor_id,
    required List<PurchaseLine> lines,
    required double paid,
  }) async {
    final data = await _backend.call('save_purchase_invoice', {
      'vendor_id': vendor_id,
      'paid': paid,
      'lines': [
        for (final line in lines)
          {'sku': line.sku, 'qty': line.qty, 'unit_cost': line.unit_cost},
      ],
    }) as Map<String, dynamic>;
    return text_of(data['transaction_id']);
  }

  @override
  Future<String> save_sales_invoice({
    required String customer_id,
    required List<PickupAllocation> lines,
    required double received,
  }) async {
    final data = await _backend.call('save_sales_invoice', {
      'customer_id': customer_id,
      'received': received,
      'lines': [
        for (final line in lines)
          {'batch_id': line.batch_id, 'qty': line.qty, 'unit_price': line.unit_price},
      ],
    }) as Map<String, dynamic>;
    return text_of(data['transaction_id']);
  }

  @override
  Future<void> log_spoilage({
    required String batch_id,
    required int qty,
    required double original_purchase_cost,
  }) async {
    await _backend.call('log_spoilage', {
      'batch_id': batch_id,
      'qty': qty,
      'original_purchase_cost': original_purchase_cost,
    });
  }

  @override
  Future<void> add_payment({
    required String customer_id,
    required double amount,
  }) async {
    await _backend.call('add_payment', {'customer_id': customer_id, 'amount': amount});
  }

  @override
  Future<void> record_invoice_payment({
    required String transaction_id,
    required double amount,
  }) async {
    await _backend.call('record_invoice_payment', {
      'transaction_id': transaction_id,
      'amount': amount,
    });
  }

  String _day_text(DateTime day) => DateFormat('yyyy-MM-dd').format(day);
}
