import '../models/morning_checklist_line.dart';
import '../state/retail_snapshot.dart';

/// Today's pickups per product, next to what is on the shelf.
/// Only products someone asked for today appear.
List<MorningChecklistLine> build_morning_checklist(
  RetailSnapshot snapshot,
  DateTime today,
) {
  final lines = <MorningChecklistLine>[];
  for (final product in snapshot.products) {
    final needed = snapshot.open_need_qty_for_sku(product.sku, today);
    if (needed == 0) continue;
    lines.add(MorningChecklistLine(
      sku: product.sku,
      needed: needed,
      in_stock: snapshot.total_stock_for_sku(product.sku),
    ));
  }
  // Biggest shortfall first, so the retailer sees what to buy before anything else.
  lines.sort((a, b) => b.to_buy_or_prep.compareTo(a.to_buy_or_prep));
  return lines;
}
