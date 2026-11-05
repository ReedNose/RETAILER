# Phase 8 changes (backend wiring)

New: lib/data/backend/backend_client.dart, backend_mappers.dart, http_retail_repository.dart
Rewritten: lib/data/retail_repository.dart (new interface), lib/data/mock/mock_retail_repository.dart
  (same rules as the backend; for demos), lib/state/retail_store.dart (thin wrappers, one reload per write),
  lib/state/retail_providers.dart (use_demo_data switch), lib/state/log_out.dart (clears session and store),
  lib/screens/login_screen.dart (server PIN check), lib/state/session_providers.dart (users_provider removed)
Edits: pubspec.yaml (http), lib/core/app_config.dart (backend_url),
  lib/screens/retailer/inventory/add_stock_screen.dart (the server makes batch ids),
  test/core_helpers_test.dart, test/phase3_test.dart, test/phase5_test.dart (new repository API)

Interface changes: sign_in, sign_out, fetch_snapshot, save_purchase_invoice, save_sales_invoice replace
  fetch_* and the per-line add_stock / sell_from_batch / add_invoice_payment. log_spoilage now takes the
  purchase cost. fetch_users is gone (login goes through sign_in).
Not compiled: run flutter pub get, flutter analyze and flutter test.
