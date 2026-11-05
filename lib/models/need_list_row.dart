/// One flat row per item. A need-list never reserves or touches stock.
class NeedListRow {
  const NeedListRow({
    required this.need_id,
    required this.created_at,
    required this.pickup_date,
    required this.customer_id,
    required this.sku,
    required this.qty,
    required this.is_done,
  });

  final String need_id;
  final DateTime created_at;
  final DateTime pickup_date; // date only
  final String customer_id;
  final String sku;
  final int qty;
  final bool is_done;

  NeedListRow marked_done() => NeedListRow(
        need_id: need_id,
        created_at: created_at,
        pickup_date: pickup_date,
        customer_id: customer_id,
        sku: sku,
        qty: qty,
        is_done: true,
      );
}
