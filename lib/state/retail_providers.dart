import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_config.dart';
import '../data/backend/http_retail_repository.dart';
import '../data/mock/mock_retail_repository.dart';
import '../data/retail_repository.dart';
import 'retail_snapshot.dart';
import 'retail_store.dart';

/// true runs the app on built-in demo data with no network. It switches on by itself while
/// backend_url is still the placeholder, or when started with --dart-define=DEMO=true.
final bool use_demo_data =
    const bool.fromEnvironment('DEMO') || backend_url.contains('REPLACE_WITH_DEPLOYMENT_ID');

final retail_repository_provider = Provider<RetailRepository>(
  (ref) => use_demo_data
      ? MockRetailRepository()
      : HttpRetailRepository(backend_url: backend_url),
);

final retail_store_provider =
    AsyncNotifierProvider<RetailStore, RetailSnapshot>(RetailStore.new);
