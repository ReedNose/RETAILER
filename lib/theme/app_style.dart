import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

/// Shared shape sizes, so every card, chip and button agrees.
class AppRadius {
  static const card = 16.0;
  static const chip = 20.0;
  static const button = 14.0;
  static const sheet = 24.0;
}

/// Soft, cool shadows. Cards that sit on the gray canvas use [soft];
/// floating things (bars, hero panels) use [lift].
class AppShadow {
  static const soft = <BoxShadow>[
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const lift = <BoxShadow>[
    BoxShadow(color: Color(0x1F0F172A), blurRadius: 24, offset: Offset(0, 10)),
  ];
}

/// Digits of equal width, so amounts line up in a column.
const money_features = <FontFeature>[FontFeature.tabularFigures()];

/// A color at the given opacity (0 to 1). Works on every Flutter version.
Color soft_tint(Color color, [double opacity = 0.12]) =>
    color.withAlpha((opacity * 255).round());
