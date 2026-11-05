import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../state/session_providers.dart';
import 'customer/customer_home_screen.dart';
import 'login_screen.dart';
import 'retailer/retailer_home_screen.dart';

/// Chooses the screen from who is logged in. Wiring only, no logic.
class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(current_user_provider);

    final Widget screen;
    if (user == null) {
      screen = const LoginScreen(key: ValueKey('login'));
    } else if (user.role == UserRole.customer) {
      screen = const CustomerHomeScreen(key: ValueKey('customer'));
    } else {
      screen = const RetailerHomeScreen(key: ValueKey('retailer'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: screen,
    );
  }
}
