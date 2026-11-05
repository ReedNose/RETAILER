/// One row of the Morning Checklist card. Computed, never stored.
class MorningChecklistLine {
  const MorningChecklistLine({
    required this.sku,
    required this.needed,
    required this.in_stock,
  });

  final String sku;
  final int needed; // sum of today's open need-list rows
  final int in_stock; // sum of warehouse rows

  int get to_buy_or_prep {
    final gap = needed - in_stock;
    return gap < 0 ? 0 : gap;
  }
}
