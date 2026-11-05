import 'package:flutter/material.dart';

/// One place for the palette. Cool gray canvas, crisp white cards, blue for
/// "selected", green for "send". Matches the reference preorder page.
class AppColors {
  static const background = Color(0xFFF8FAFC);
  static const card = Colors.white;
  static const ink = Color(0xFF0F172A);
  static const ink_soft = Color(0xFF64748B);
  static const ink_faint = Color(0xFF94A3B8);
  static const line = Color(0xFFE2E8F0); // hairline borders
  static const accent = Color(0xFF2563EB); // selected card border, links
  static const accent_dark = Color(0xFF1D4ED8);
  static const accent_tint = Color(0xFFEFF6FF); // selected card background
  static const brand = Color(0xFF10B981); // Send Order green
  static const brand_dark = Color(0xFF059669);
  static const brand_tint = Color(0xFFECFDF5);
  static const fresh = Color(0xFF16A34A);
  static const priority = Color(0xFFEA580C); // Day 2 orange
  static const priority_bg = Color(0xFFFFF1E6);
  static const danger = Color(0xFFDC2626);
  static const danger_tint = Color(0xFFFEF2F2);

  /// Blue hero panels (Today summary, profit card).
  static const hero_gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
  );

  /// Green primary actions.
  static const brand_gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );
}
