# Top-level pass (nothing here was compiled: there was no Flutter SDK available)

A custom checker (bracket balance, import paths, missing imports, unused imports) ran clean after every phase.
Please run `flutter pub get`, `flutter analyze` and `flutter test`, and paste back anything it reports.

## Phase 1: foundation
- Design system: `theme/app_colors.dart` (new tints, gradients), `theme/app_style.dart` (radius, shadows,
  tabular money digits, `soft_tint`), richer `app_theme.dart` (nav bar, buttons, chips, inputs, sheets).
- Shared widgets: `AppCard`, `SectionHeader`, `StatusPill`, `IconBadge`, `StatTile`, `SoftBar`,
  `Skeleton` loaders, `ErrorView` with retry, `EmptyState`, `PinPad`.
- Login is a PIN pad with dots, shake on a wrong PIN and hardware-keyboard support.
- Demo data turns on by itself while `backend_url` is still the placeholder (or `--dart-define=DEMO=true`).
- Content stays in a 720 px column on wide screens; mouse and trackpad can drag-scroll.
- Tests now use `test/test_support.dart` (`demo_container()`), so they never touch the network.

## Phase 2: customer
- Search, category chips, adaptive grid, staggered card entrance, pull to refresh, loading skeletons.
- "Order sent for tomorrow" card with a Change button (loads the sent order back into the cart).
- Tap the item count to review the order in a sheet; Send Order works from there too.
- Fixed: Send Order crashed after saving (customer name lookup). Backend `read_customer_view` now returns the name.

## Phase 3: retailer home
- Today: gradient summary, "sell these first" banner, four quick actions, checklist with coverage bars,
  pickup tiles with emoji summaries. Tab badges for waiting customers and Day 2 batches.
- Inventory: summary strip (units, retail value, Day 2), search, Day 2 filter, remaining-stock bars.

## Phase 4: money, invoices, reports
- Money: "Customers owe you" card with the biggest balances; invoice preview styled like the PDF.
- Invoice list/detail: status pills, payment progress, gradient header.
- Reports: profit hero, bars by customer/vendor/product, icons on ledger rows, numbered steps.
- Sale and stock forms show a live total; Receive payment shows the balance before and after.

## Phase 5: finishing
- Picked Up screen: customer header with a "lines ready" progress bar.
