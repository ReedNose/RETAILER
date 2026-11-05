/// One slice of a pickup: take [qty] from [batch_id] at [unit_price].
/// A discount is just a lower unit_price here.
class PickupAllocation {
  const PickupAllocation({
    required this.batch_id,
    required this.qty,
    required this.unit_price,
  });

  final String batch_id;
  final int qty;
  final double unit_price;
}
