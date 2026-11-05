# Phase 9 (check, fix, visuals). Still not compiled: no Flutter SDK here.

Fixed
- Customer "Send Order" crashed after saving (customers list is empty in the customer view, so
  firstWhere threw and WhatsApp never opened). The backend's read_customer_view now returns
  `customer: {customer_id, name}`; the app uses it, falls back safely, and shows an error
  snackbar instead of failing silently. Redeploy the backend (api.gs) for the name to appear.
- Removed controllers are disposed after the frame (invoice entry, pickup editor).
- pubspec sdk raised to >=3.6.0 (CardThemeData, TabBarThemeData, withValues need Flutter 3.27+).

Visuals
- Theme: flat app bar, styled navigation bar, tabs, buttons, inputs, floating dark snackbars.
- New lib/widgets/shared/state_views.dart: ErrorView (Try again) and EmptyState.
- Login: logo tile, bolder title. Customer: qty badge on cards, stock dot, pull to refresh.
- Today: two stat tiles, pull to refresh. Inventory and invoice lists: empty states.
- RetailStore.refresh() added (keeps old data if the call fails).
