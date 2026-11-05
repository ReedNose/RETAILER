import '../core/date_helpers.dart';
import '../models/ledger_row.dart';
import 'report_type.dart';

/// The one filter every report uses. Filters combine with AND, and a null
/// filter means "all". Every report number is summed from the rows returned here.
///
/// Customer and supplier are not mutually exclusive in this function. Setting
/// both returns nothing, which is correct because a row has only one source.
List<LedgerRow> filter_ledger_rows({
  required List<LedgerRow> rows,
  required ReportType report_type,
  String? customer_id,
  String? vendor_id,
  String? sku,
  String? batch_id,
  DateTime? start_date,
  DateTime? end_date,
}) {
  final start = start_date == null ? null : date_only(start_date);
  final end = end_date == null ? null : date_only(end_date);

  return rows.where((row) {
    if (!_matches_type(row, report_type)) return false;
    if (customer_id != null &&
        !(row.source_type == SourceType.customer && row.source_id == customer_id)) {
      return false;
    }
    if (vendor_id != null &&
        !(row.source_type == SourceType.vendor && row.source_id == vendor_id)) {
      return false;
    }
    if (sku != null && row.sku != sku) return false;
    if (batch_id != null && row.batch_id != batch_id) return false;
    final day = date_only(row.date);
    if (start != null && day.isBefore(start)) return false;
    if (end != null && day.isAfter(end)) return false;
    return true;
  }).toList();
}

/// Customer = sales to customers, vendor = purchases from vendors, overall = everything.
bool _matches_type(LedgerRow row, ReportType report_type) => switch (report_type) {
      ReportType.customer => row.transaction_type == TransactionType.sale &&
          row.source_type == SourceType.customer,
      ReportType.vendor => row.transaction_type == TransactionType.purchase &&
          row.source_type == SourceType.vendor,
      ReportType.overall => true,
    };
