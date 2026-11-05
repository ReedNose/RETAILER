/// Per-product qty and amount, for a customer or vendor report.
class ProductTotals {
  const ProductTotals({
    required this.sku,
    required this.qty,
    required this.amount,
  });

  final String sku;
  final int qty; // always shown positive
  final double amount;
}

/// Per-product sales, purchases and spoilage, for the Overall report.
class ProductSplit {
  const ProductSplit({
    required this.sku,
    required this.sales,
    required this.purchases,
    required this.spoilage,
  });

  final String sku;
  final double sales;
  final double purchases;
  final double spoilage;
}

/// One customer or vendor and their total.
class NameTotal {
  const NameTotal({
    required this.id,
    required this.name,
    required this.amount,
  });

  final String id;
  final String name;
  final double amount;
}
