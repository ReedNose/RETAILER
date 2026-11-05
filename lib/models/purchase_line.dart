/// One line of a purchase invoice being entered: buy [qty] of [sku] at [unit_cost].
/// The batch id is made by the app on save, never typed.
class PurchaseLine {
  const PurchaseLine({
    required this.sku,
    required this.qty,
    required this.unit_cost,
  });

  final String sku;
  final int qty;
  final double unit_cost;
}
