import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'searchable_option.dart';
import 'searchable_sheet.dart';

/// A form field that opens a searchable list. There is no text input, so a
/// relational value can only ever be one of the options (no typos).
class SearchableDropdown<T> extends StatelessWidget {
  const SearchableDropdown({
    super.key,
    required this.label,
    required this.sheet_title,
    required this.options,
    required this.selected,
    required this.on_changed,
    this.enabled = true,
  });

  final String label;
  final String sheet_title;
  final List<SearchableOption<T>> options;
  final SearchableOption<T>? selected;
  final ValueChanged<T> on_changed;
  final bool enabled;

  Future<void> _open(BuildContext context) async {
    final choice = await show_searchable_sheet<T>(
      context: context,
      title: sheet_title,
      options: options,
    );
    if (choice != null) on_changed(choice.value);
  }

  @override
  Widget build(BuildContext context) {
    final chosen = selected;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(label,
                style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
          ),
          Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: enabled ? () => _open(context) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    if (chosen?.leading != null) ...[
                      Text(chosen!.leading!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        chosen?.label ?? 'Tap to choose',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: chosen == null ? FontWeight.w400 : FontWeight.w600,
                          color: chosen == null ? AppColors.ink_soft : AppColors.ink,
                        ),
                      ),
                    ),
                    const Icon(Icons.unfold_more_rounded, color: AppColors.ink_soft),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
