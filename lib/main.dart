import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/app_root.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: RetailPreorderApp()));
}

/// Lets a mouse or trackpad drag-scroll lists and pull to refresh, like a finger does.
/// Without this the web and desktop builds only scroll with the wheel.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class RetailPreorderApp extends StatelessWidget {
  const RetailPreorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fresh Preorder',
      debugShowCheckedModeBanner: false,
      theme: build_app_theme(),
      scrollBehavior: const AppScrollBehavior(),
      // The app is phone-first. On a wide window (web, tablet) the content stays in a
      // comfortable column instead of stretching edge to edge.
      builder: (context, child) => ColoredBox(
        color: AppColors.background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: child,
          ),
        ),
      ),
      home: const AppRoot(),
    );
  }
}
