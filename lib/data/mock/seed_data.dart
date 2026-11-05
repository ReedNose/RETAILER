// Mock starting data. Dates are relative to "today" so the demo always shows
// a fresh batch and a Day 2 priority batch, whichever day you run the app.
import '../../core/date_helpers.dart';
import '../../models/app_user.dart';
import '../../models/customer.dart';
import '../../models/ledger_row.dart';
import '../../models/need_list_row.dart';
import '../../models/product.dart';
import '../../models/vendor.dart';
import '../../models/warehouse_batch.dart';

const seed_products = <Product>[
  Product(sku: 'ML', name: 'Whole Milk', emoji: '🥛', category: 'Dairy', default_retail_price: 3.50, shelf_life_days: 2),
  Product(sku: 'EG', name: 'Eggs (12pk)', emoji: '🥚', category: 'Dairy', default_retail_price: 5.00, shelf_life_days: 3),
  Product(sku: 'BR', name: 'Sourdough Bread', emoji: '🍞', category: 'Bakery', default_retail_price: 6.50, shelf_life_days: 2),
  Product(sku: 'CR', name: 'Croissants (4pk)', emoji: '🥐', category: 'Bakery', default_retail_price: 8.00, shelf_life_days: 2),
  Product(sku: 'JU', name: 'Orange Juice', emoji: '🍊', category: 'Beverages', default_retail_price: 4.50, shelf_life_days: 2),
  Product(sku: 'CH', name: 'Cheese Block', emoji: '🧀', category: 'Dairy', default_retail_price: 7.00, shelf_life_days: 5),
  Product(sku: 'BT', name: 'Butter', emoji: '🧈', category: 'Dairy', default_retail_price: 4.00, shelf_life_days: 4),
  Product(sku: 'YG', name: 'Yogurt', emoji: '🥣', category: 'Dairy', default_retail_price: 3.00, shelf_life_days: 3),
  Product(sku: 'AP', name: 'Apples (1kg)', emoji: '🍎', category: 'Produce', default_retail_price: 4.50, shelf_life_days: 5),
  Product(sku: 'BN', name: 'Bananas', emoji: '🍌', category: 'Produce', default_retail_price: 2.50, shelf_life_days: 3),
  Product(sku: 'TM', name: 'Tomatoes', emoji: '🍅', category: 'Produce', default_retail_price: 3.50, shelf_life_days: 3),
];

const seed_vendors = <Vendor>[
  Vendor(vendor_id: 'V001', name: 'Green Farm Dairy', whatsapp_no: '+15551001'),
  Vendor(vendor_id: 'V002', name: 'Sunrise Bakery', whatsapp_no: '+15551002'),
  Vendor(vendor_id: 'V003', name: 'Valley Produce Co', whatsapp_no: '+15551003'),
];

const seed_customers = <Customer>[
  Customer(customer_id: 'C001', name: 'Maria Santos', whatsapp_no: '+15552001'),
  Customer(customer_id: 'C002', name: 'James Chen', whatsapp_no: '+15552002'),
  Customer(customer_id: 'C003', name: 'Sarah Williams', whatsapp_no: '+15552003'),
  Customer(customer_id: 'C004', name: 'David Kim', whatsapp_no: '+15552004'),
];

const seed_users = <AppUser>[
  AppUser(user_id: 'U001', role: UserRole.retailer, customer_id: null, pin_hash: '1234'),
  AppUser(user_id: 'U002', role: UserRole.customer, customer_id: 'C001', pin_hash: '1111'),
  AppUser(user_id: 'U003', role: UserRole.customer, customer_id: 'C002', pin_hash: '2222'),
];

/// (batch_id, vendor_id, days_ago, bought_qty, unit_cost, still_in_stock)
/// One source of truth so the warehouse and the PURCHASE ledger rows always agree.
const _seed_batches = <(String, String, int, int, double, int)>[
  ('ML_2401', 'V001', 0, 12, 2.00, 8),
  ('ML_2402', 'V001', 1, 5, 2.00, 3), // Day 2 priority
  ('EG_2403', 'V001', 0, 8, 3.00, 5),
  ('BR_2404', 'V002', 0, 10, 3.50, 6),
  ('BR_2405', 'V002', 1, 4, 3.50, 2), // Day 2 priority
  ('CR_2406', 'V002', 0, 8, 4.50, 4),
  ('JU_2407', 'V003', 0, 10, 2.50, 7),
  ('JU_2408', 'V003', 1, 4, 2.50, 2), // Day 2 priority
  ('CH_2409', 'V001', 0, 6, 4.00, 4),
  ('AP_2410', 'V003', 0, 15, 2.50, 10),
  ('BN_2411', 'V003', 2, 8, 1.50, 3), // shelf life 3, so priority
  ('YG_2412', 'V001', 0, 10, 1.80, 6),
];

List<WarehouseBatch> build_seed_warehouse(DateTime today) => [
      for (final b in _seed_batches)
        WarehouseBatch(
          batch_id: b.$1,
          vendor_id: b.$2,
          batch_date: date_only(today.subtract(Duration(days: b.$3))),
          current_qty: b.$6,
        ),
    ];

List<LedgerRow> build_seed_ledger(DateTime today) {
  final rows = <LedgerRow>[];
  // Same vendor + same day = one purchase invoice (one shared transaction_id).
  final purchase_ids = <String, String>{};
  for (final b in _seed_batches) {
    final bought_on = date_only(today.subtract(Duration(days: b.$3)));
    final invoice_id = purchase_ids.putIfAbsent(
      '${b.$2}-${b.$3}',
      () => 'TRX-P${(purchase_ids.length + 1).toString().padLeft(3, '0')}',
    );
    rows.add(LedgerRow(
      transaction_id: invoice_id,
      created_at: bought_on.add(const Duration(hours: 6)),
      date: bought_on,
      transaction_type: TransactionType.purchase,
      source_type: SourceType.vendor,
      source_id: b.$2,
      batch_id: b.$1,
      qty: b.$4,
      unit_price: b.$5,
      total_amount: b.$4 * b.$5,
    ));
  }
  // A few earlier sales so Reports has something to show on first run.
  // Milk batch ML_2402: bought 5, 3 left, so 2 sold (matches the warehouse).
  rows.add(LedgerRow(
    transaction_id: 'TRX-S001',
    created_at: today.add(const Duration(hours: 9)),
    date: date_only(today),
    transaction_type: TransactionType.sale,
    source_type: SourceType.customer,
    source_id: 'C001',
    batch_id: 'ML_2402',
    qty: -2,
    unit_price: 3.50,
    total_amount: 7.00,
  ));
  return rows;
}

List<NeedListRow> build_seed_need_list(DateTime today) {
  final day = date_only(today);
  NeedListRow row(String id, String customer_id, String sku, int qty) => NeedListRow(
        need_id: id,
        created_at: day.add(const Duration(hours: 7)),
        pickup_date: day,
        customer_id: customer_id,
        sku: sku,
        qty: qty,
        is_done: false,
      );
  return [
    row('N001', 'C001', 'ML', 2),
    row('N002', 'C001', 'BR', 1),
    row('N003', 'C002', 'EG', 3),
    row('N004', 'C003', 'JU', 2),
    row('N005', 'C004', 'ML', 1),
    row('N006', 'C004', 'CR', 2),
  ];
}
