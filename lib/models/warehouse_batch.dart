/// One row of the temporary `warehouse` table (live stock only).
class WarehouseBatch {
  const WarehouseBatch({
    required this.batch_id,
    required this.vendor_id,
    required this.batch_date,
    required this.current_qty,
  });

  final String batch_id; // {sku}_{unique_string}
  final String vendor_id;
  final DateTime batch_date; // date only
  final int current_qty;

  String get sku => batch_id.split("_").first;

  WarehouseBatch with_qty(int new_qty) => WarehouseBatch(
        batch_id: batch_id,
        vendor_id: vendor_id,
        batch_date: batch_date,
        current_qty: new_qty,
      );
}
