class Product {
  const Product({
    required this.sku,
    required this.name,
    required this.emoji,
    required this.category,
    required this.default_retail_price,
    this.shelf_life_days = 2,
  });

  final String sku; // e.g. "ML" (never contains an underscore)
  final String name;
  final String emoji;
  final String category;
  final double default_retail_price;
  final int shelf_life_days;
}
