import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_style.dart';

/// The one white card: hairline border, optional soft shadow, optional tap.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.on_tap,
    this.color = AppColors.card,
    this.border_color = AppColors.line,
    this.shadow = false,
    this.radius = AppRadius.card,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? on_tap;
  final Color color;
  final Color border_color;
  final bool shadow;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final content = Padding(padding: padding, child: child);
    final tap = on_tap;

    final Widget card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: shape,
        border: Border.all(color: border_color),
        boxShadow: shadow ? AppShadow.soft : null,
      ),
      child: tap == null
          ? content
          : Material(
              color: Colors.transparent,
              borderRadius: shape,
              child: InkWell(borderRadius: shape, onTap: tap, child: content),
            ),
    );

    final outer = margin;
    return outer == null ? card : Padding(padding: outer, child: card);
  }
}

/// Bold section title with an optional widget on the right (a count, a link).
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final end = trailing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          if (end != null) end,
        ],
      ),
    );
  }
}

/// Small rounded label: "Paid", "DAY 2", "Need 4 more".
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text, required this.color, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final glyph = icon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: soft_tint(color),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            Icon(glyph, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Rounded square with a tinted background and one icon.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: soft_tint(color),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}

/// A number with a label and an icon: "3 pickups today".
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin rounded progress bar. [value] is 0 to 1.
class SoftBar extends StatelessWidget {
  const SoftBar({super.key, required this.value, required this.color, this.height = 6});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final safe = value.isNaN ? 0.0 : (value < 0 ? 0.0 : (value > 1 ? 1.0 : value));
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: safe,
        minHeight: height,
        color: color,
        backgroundColor: AppColors.line,
      ),
    );
  }
}
