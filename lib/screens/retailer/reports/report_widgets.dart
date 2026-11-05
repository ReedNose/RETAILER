import 'package:flutter/material.dart';

import '../../../invoices/format_dollars.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_style.dart';
import '../../../widgets/shared/app_card.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => SectionHeader(text);
}

class EmptyNote extends StatelessWidget {
  const EmptyNote({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Text('Nothing matches these filters.',
          style: TextStyle(color: AppColors.ink_soft)),
    );
  }
}

/// A single big number card (total sales, total purchases, ...).
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.amount,
    required this.accent,
    this.icon,
  });

  final String label;
  final double amount;
  final Color accent;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final glyph = icon;
    return AppCard(
      shadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (glyph != null) ...[
                IconBadge(icon: glyph, color: accent, size: 32),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: AppColors.ink_soft, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            format_dollars(amount),
            style: TextStyle(
              color: accent,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFeatures: money_features,
            ),
          ),
        ],
      ),
    );
  }
}

/// The headline of the Overall report: gross profit, with the three numbers behind it.
class ProfitHero extends StatelessWidget {
  const ProfitHero({
    super.key,
    required this.profit,
    required this.sales,
    required this.purchases,
    required this.spoilage,
  });

  final double profit;
  final double sales;
  final double purchases;
  final double spoilage;

  @override
  Widget build(BuildContext context) {
    final is_loss = profit < 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: is_loss
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
              )
            : AppColors.hero_gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadow.lift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(is_loss ? 'Gross loss' : 'Gross profit',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(format_dollars(profit),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  fontFeatures: money_features)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _HeroNumber(label: 'Sales', amount: sales)),
              const SizedBox(width: 10),
              Expanded(child: _HeroNumber(label: 'Purchases', amount: purchases)),
              const SizedBox(width: 10),
              Expanded(child: _HeroNumber(label: 'Spoilage', amount: spoilage)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroNumber extends StatelessWidget {
  const _HeroNumber({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(36),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(format_dollars(amount),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: money_features)),
          ),
        ],
      ),
    );
  }
}

/// One line of a per-party or per-product list: a name, an amount and, when
/// [share] is given (0 to 1), a bar showing how big it is next to the others.
class AmountRow extends StatelessWidget {
  const AmountRow({
    super.key,
    required this.name,
    required this.amount,
    this.detail,
    this.share,
    this.color = AppColors.accent,
  });

  final String name;
  final double amount;
  final String? detail;
  final double? share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final note = detail;
    final bar = share;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (note != null)
                      Text(note,
                          style: const TextStyle(color: AppColors.ink_soft, fontSize: 12)),
                  ],
                ),
              ),
              Text(format_dollars(amount),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontFeatures: money_features)),
            ],
          ),
          if (bar != null) ...[
            const SizedBox(height: 10),
            SoftBar(value: bar, color: color),
          ],
        ],
      ),
    );
  }
}

/// Share of the biggest value in a list, 0 to 1, for the bars.
double bar_share(double amount, double biggest) =>
    biggest <= 0 ? 0.0 : amount / biggest;
