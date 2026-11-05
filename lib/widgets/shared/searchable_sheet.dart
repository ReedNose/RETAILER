import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'searchable_option.dart';

/// Wrapped in a record so "dismissed" (null) and "picked the All option" differ.
typedef SheetChoice<T> = ({T value});

/// Opens a bottom sheet with a search box. Returns null if the sheet was dismissed.
Future<SheetChoice<T>?> show_searchable_sheet<T>({
  required BuildContext context,
  required String title,
  required List<SearchableOption<T>> options,
}) {
  return showModalBottomSheet<SheetChoice<T>>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SearchableSheet<T>(title: title, options: options),
  );
}

class _SearchableSheet<T> extends StatefulWidget {
  const _SearchableSheet({required this.title, required this.options});

  final String title;
  final List<SearchableOption<T>> options;

  @override
  State<_SearchableSheet<T>> createState() => _SearchableSheetState<T>();
}

class _SearchableSheetState<T> extends State<_SearchableSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final shown = query.isEmpty
        ? widget.options
        : widget.options
            .where((o) =>
                o.label.toLowerCase().contains(query) ||
                (o.subtitle ?? '').toLowerCase().contains(query))
            .toList();
    final height = MediaQuery.of(context).size.height * 0.7;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: shown.isEmpty
                    ? const Center(
                        child: Text('No match',
                            style: TextStyle(color: AppColors.ink_soft)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                        itemCount: shown.length,
                        itemBuilder: (context, index) {
                          final option = shown[index];
                          return ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            leading: option.leading == null
                                ? null
                                : Text(option.leading!,
                                    style: const TextStyle(fontSize: 24)),
                            title: Text(option.label,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: option.subtitle == null ? null : Text(option.subtitle!),
                            onTap: () => Navigator.of(context)
                                .pop<SheetChoice<T>>((value: option.value)),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
