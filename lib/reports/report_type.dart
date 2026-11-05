/// Which slice of the ledger a report reads.
enum ReportType { customer, vendor, overall }

extension ReportTypeLabel on ReportType {
  String get label => switch (this) {
        ReportType.customer => 'Customer',
        ReportType.vendor => 'Vendor',
        ReportType.overall => 'Overall',
      };
}
