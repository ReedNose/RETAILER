import '../../state/retail_snapshot.dart';
import '../shared/searchable_option.dart';

/// Products that have live stock, for sale and spoilage pickers.
List<SearchableOption<String>> product_options_in_stock(RetailSnapshot snapshot) => [
      for (final product in snapshot.products)
        if (snapshot.batches_for_sku(product.sku).isNotEmpty)
          SearchableOption<String>(
            value: product.sku,
            label: product.name,
            subtitle: '${snapshot.total_stock_for_sku(product.sku)} in stock',
            leading: product.emoji,
          ),
    ];

/// Every product, for the add-stock picker.
List<SearchableOption<String>> product_options_all(RetailSnapshot snapshot) => [
      for (final product in snapshot.products)
        SearchableOption<String>(
          value: product.sku,
          label: product.name,
          subtitle: product.category,
          leading: product.emoji,
        ),
    ];
