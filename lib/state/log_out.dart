import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cart_providers.dart';
import 'retail_providers.dart';
import 'session_providers.dart';

void log_out(WidgetRef ref) {
  ref.read(cart_provider.notifier).clear();
  ref.read(retail_repository_provider).sign_out();
  // Drop the last user's data, so the next sign-in never sees it.
  ref.invalidate(retail_store_provider);
  ref.read(current_user_provider.notifier).state = null;
}
