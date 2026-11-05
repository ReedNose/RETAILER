import '../../state/retail_snapshot.dart';
import '../shared/searchable_option.dart';

/// Every customer, for the invoice and payment pickers.
List<SearchableOption<String>> customer_options(RetailSnapshot snapshot) => [
      for (final customer in snapshot.customers)
        SearchableOption<String>(
          value: customer.customer_id,
          label: customer.name,
          subtitle: customer.whatsapp_no,
          leading: '👤',
        ),
    ];
