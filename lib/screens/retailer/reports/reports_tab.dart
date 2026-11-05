import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sku_helpers.dart';
import '../../../models/ledger_row.dart';
import '../../../reports/filter_ledger_rows.dart';
import '../../../reports/report_type.dart';
import '../../../state/retail_providers.dart';
import '../../../state/retail_snapshot.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/shared/searchable_dropdown.dart';
import '../../../widgets/shared/searchable_option.dart';
import 'date_range_field.dart';
import 'overall_results.dart';
import 'party_results.dart';
import '../../../widgets/shared/skeleton.dart';
import '../../../widgets/shared/state_views.dart';

/// Reports are calculated when Generate is tapped, shown, and forgotten.
/// Nothing is stored. Changing any filter clears the old result.
class ReportsTab extends ConsumerStatefulWidget {
  const ReportsTab({super.key});

  @override
  ConsumerState<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<ReportsTab> {
  ReportType? _type;
  String? _name_id; // the customer or vendor, for those two reports
  String? _customer_id; // overall report only
  String? _supplier_id; // overall report only
  String? _sku;
  String? _batch_id; // overall report only
  DateTime? _start;
  DateTime? _end;
  List<LedgerRow>? _rows;

  /// Any filter change clears the old result.
  void _edit(VoidCallback change) {
    setState(() {
      change();
      _rows = null;
    });
  }

  void _choose_type(ReportType type) {
    _edit(() {
      _type = type;
      _name_id = null;
      _customer_id = null;
      _supplier_id = null;
      _sku = null;
      _batch_id = null;
      _start = null;
      _end = null;
    });
  }

  void _generate(RetailSnapshot snapshot) {
    final type = _type;
    if (type == null) return;
    final rows = filter_ledger_rows(
      rows: snapshot.ledger,
      report_type: type,
      customer_id: switch (type) {
        ReportType.customer => _name_id,
        ReportType.overall => _customer_id,
        ReportType.vendor => null,
      },
      vendor_id: switch (type) {
        ReportType.vendor => _name_id,
        ReportType.overall => _supplier_id,
        ReportType.customer => null,
      },
      sku: _sku,
      batch_id: type == ReportType.overall ? _batch_id : null,
      start_date: _start,
      end_date: _end,
    )..sort((a, b) => b.created_at.compareTo(a.created_at)); // newest first
    setState(() => _rows = rows);
  }

  List<SearchableOption<String?>> _customer_options(RetailSnapshot snapshot) => [
        const SearchableOption<String?>(value: null, label: 'All customers'),
        for (final customer in snapshot.customers)
          SearchableOption<String?>(value: customer.customer_id, label: customer.name),
      ];

  List<SearchableOption<String?>> _vendor_options(RetailSnapshot snapshot) => [
        const SearchableOption<String?>(value: null, label: 'All vendors'),
        for (final vendor in snapshot.vendors)
          SearchableOption<String?>(value: vendor.vendor_id, label: vendor.name),
      ];

  List<SearchableOption<String?>> _product_options(RetailSnapshot snapshot) => [
        const SearchableOption<String?>(value: null, label: 'All products'),
        for (final product in snapshot.products)
          SearchableOption<String?>(
            value: product.sku,
            label: product.name,
            leading: product.emoji,
          ),
      ];

  /// Batches from the ledger (not the warehouse, which drops empty batches).
  /// When a product is chosen, only that product's batches are listed.
  List<SearchableOption<String?>> _batch_options(RetailSnapshot snapshot) {
    final sku = _sku;
    final ids = <String>{
      for (final row in snapshot.ledger)
        if (sku == null || row.sku == sku) row.batch_id,
    }.toList()
      ..sort();
    return [
      const SearchableOption<String?>(value: null, label: 'All batches'),
      for (final id in ids)
        SearchableOption<String?>(
          value: id,
          label: id,
          subtitle: snapshot.product_by_sku(sku_from_batch_id(id))?.name,
        ),
    ];
  }

  List<Widget> _filters_for(ReportType type, RetailSnapshot snapshot) {
    final product_options = _product_options(snapshot);
    final product_field = SearchableDropdown<String?>(
      label: 'Product',
      sheet_title: 'Choose product',
      options: product_options,
      selected: option_for(product_options, _sku),
      on_changed: (value) => _edit(() {
        _sku = value;
        // Drop a batch that belongs to a different product.
        final batch = _batch_id;
        if (batch != null && value != null && sku_from_batch_id(batch) != value) {
          _batch_id = null;
        }
      }),
    );
    final date_field = DateRangeField(
      start: _start,
      end: _end,
      on_changed: (start, end) => _edit(() {
        _start = start;
        _end = end;
      }),
    );

    if (type == ReportType.overall) {
      final supplier_options = _vendor_options(snapshot);
      final customer_options = _customer_options(snapshot);
      final batch_options = _batch_options(snapshot);
      // A ledger row has one source, so supplier and customer cannot both be set.
      return [
        SearchableDropdown<String?>(
          label: 'Supplier',
          sheet_title: 'Choose supplier',
          options: supplier_options,
          selected: option_for(supplier_options, _supplier_id),
          enabled: _customer_id == null,
          on_changed: (value) => _edit(() {
            _supplier_id = value;
            if (value != null) _customer_id = null;
          }),
        ),
        const SizedBox(height: 14),
        SearchableDropdown<String?>(
          label: 'Customer',
          sheet_title: 'Choose customer',
          options: customer_options,
          selected: option_for(customer_options, _customer_id),
          enabled: _supplier_id == null,
          on_changed: (value) => _edit(() {
            _customer_id = value;
            if (value != null) _supplier_id = null;
          }),
        ),
        const SizedBox(height: 14),
        product_field,
        const SizedBox(height: 14),
        SearchableDropdown<String?>(
          label: 'Batch ID',
          sheet_title: 'Choose batch',
          options: batch_options,
          selected: option_for(batch_options, _batch_id),
          on_changed: (value) => _edit(() => _batch_id = value),
        ),
        const SizedBox(height: 14),
        date_field,
      ];
    }

    final is_customer = type == ReportType.customer;
    final name_options = is_customer ? _customer_options(snapshot) : _vendor_options(snapshot);
    return [
      SearchableDropdown<String?>(
        label: is_customer ? 'Customer' : 'Vendor',
        sheet_title: is_customer ? 'Choose customer' : 'Choose vendor',
        options: name_options,
        selected: option_for(name_options, _name_id),
        on_changed: (value) => _edit(() => _name_id = value),
      ),
      const SizedBox(height: 14),
      product_field,
      const SizedBox(height: 14),
      date_field,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final snapshot_async = ref.watch(retail_store_provider);

    return snapshot_async.when(
      loading: () => const SkeletonList(count: 4),
      error: (error, _) => ErrorView(
        error: error,
        on_retry: () => ref.invalidate(retail_store_provider),
      ),
      data: (snapshot) {
        final type = _type;
        final rows = _rows;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            const _StepHeader(number: 1, title: 'Report type'),
            const SizedBox(height: 10),
            SegmentedButton<ReportType>(
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: [
                for (final option in ReportType.values)
                  ButtonSegment<ReportType>(value: option, label: Text(option.label)),
              ],
              selected: type == null ? <ReportType>{} : <ReportType>{type},
              onSelectionChanged: (choice) {
                if (choice.isNotEmpty) _choose_type(choice.first);
              },
            ),
            if (type != null) ...[
              const SizedBox(height: 22),
              const _StepHeader(number: 2, title: 'Filters (all optional)'),
              const SizedBox(height: 10),
              ..._filters_for(type, snapshot),
            ],
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: type == null ? null : () => _generate(snapshot),
              child: Text(type == null ? 'Choose a report type first' : 'Generate'),
            ),
            if (type != null && rows != null) ...[
              const SizedBox(height: 24),
              if (type == ReportType.overall)
                OverallResults(rows: rows, snapshot: snapshot)
              else
                PartyResults(report_type: type, rows: rows, snapshot: snapshot),
            ],
          ],
        );
      },
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.number, required this.title});

  final int number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
          child: Text('$number',
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ],
    );
  }
}
