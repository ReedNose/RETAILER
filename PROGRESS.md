# Build progress (ticked as each phase ships)

Legend: `[x]` written and delivered. All code is **unverified**: no Flutter SDK was
available when writing, so run `flutter analyze` and `flutter test` and report errors.

## Phase 1 - Foundation
- [x] Flutter project config (`pubspec.yaml`, Riverpod, url_launcher, google_fonts, intl)
- [x] `snake_case` lint rule switched off in `analysis_options.yaml`
- [x] Models for every table (`products`, `vendors`, `customers`, `users`, `warehouse`, `need_list`, `ledger`)
- [x] `sku` helper on batch models (`batch_id.split('_').first`)
- [x] Day 2 priority rule: `age >= shelf_life_days - 1`
- [x] Seed data (relative dates, consistent warehouse and ledger)
- [x] Swappable `RetailRepository` + in-memory mock
- [x] Warehouse row deleted at 0; ledger append-only; spoilage priced at purchase cost
- [x] Riverpod store, theme (Poppins, soft gray canvas, white cards)
- [x] Unit tests for helpers and repository rules

## Phase 2 - Customer view
- [x] Mock PIN login (retailer or customer, from `users`)
- [x] Product grid, no prices shown
- [x] Total stock per product only (no batch dates, no vendors), informational, never blocks ordering
- [x] Pill `+` / `-` buttons with animation
- [x] Card scales slightly on tap, soft shadows
- [x] Floating glass-morphism checkout bar with total item count
- [x] "Send Order" silent save to `need_list` (next-day pickup, no stock reservation)
- [x] WhatsApp handoff with pre-filled, formatted message (`url_launcher`)
- [x] Cart state, double-tap protection while sending, log out
- [x] Tests for cart and message formatting

## Phase 3 - Retailer view (delivered, not yet compiled)
- [x] Inventory list grouped by batch date, orange Day 2 priority cards
- [x] Morning Checklist (needed / in_stock / to_buy_or_prep)
- [x] "Picked Up" flow with manual batch choice (Day 2 first), creates `SALE` rows
- [x] Discount = lower `unit_price` on the sale
- [x] Add stock form (searchable dropdowns, batch_id made by the app before saving)
- [x] Spoilage form
- [x] Walk-in sale form
- [x] Searchable dropdown widget (no free text for relational data)
- [ ] Not compiled yet: run `flutter analyze` and `flutter test`

## Phase 4 - Reports (delivered, not yet compiled)
- [x] Report type switch (Customer / Vendor / Overall), Generate disabled until chosen
- [x] One `filter_ledger_rows` function
- [x] Customer and Vendor filters (name, product, date range + quick picks)
- [x] Overall filters (supplier, customer, product, batch id, date range)
- [x] Supplier and customer mutually exclusive
- [x] Customer / Vendor results (total card, per-product breakdown, row list)
- [x] Overall results (4 KPI cards incl. Profit, by customer, by vendor, per product, rows)
- [ ] Not compiled yet: run `flutter analyze` and `flutter test`

## Phase 2 review pass
- [x] Replaced `.firstOrNull` (collection extension) with `first_where_or_null` in `lib/core/first_or_null.dart`
- [ ] Not compiled: Flutter SDK could not be downloaded in the build sandbox. Run `flutter analyze` and `flutter test`.

## Phase 5 - Payments and invoice PDF (delivered, not yet compiled)
- [x] `Payment` model in its own table (the ledger and every report are untouched)
- [x] Receive Payment form (customer picker, amount)
- [x] Balance logic: old balance = sales before the day - payments before the day
- [x] Invoice per customer per day, no tax: grand total, old balance, payments received, new balance
- [x] Invoice number INV-YYYYMMDD-<customer_id>, lines merged per product
- [x] PDF builder and share sheet (pick WhatsApp, then the customer chat)
- [x] New Money tab: customer + date, preview, Share invoice PDF, Receive payment
- [ ] Not compiled yet: run `flutter pub get`, `flutter analyze` and `flutter test`

## Phase 6 - Restyle to match the reference preorder page (not yet compiled)
- [x] Palette (gray canvas, blue selected, green send) and Inter font
- [x] Customer screen: white header, bordered cards with blue selected state, always-visible - n + pill, bottom Send Order bar. No prices anywhere on the customer side
- [x] Invoice PDF: shop name, blue INVOICE and rule, Bill to box, uppercase table headers, green New balance box, dollar signs
- [ ] Not compiled yet

## Phase 7 - Purchase and Sales invoices (not yet compiled)
- [x] Invoice = all ledger rows with the same transaction_id
- [x] New Invoices destination with two tabs: Purchases (vendors) and Sales (customers)
- [x] List newest first, tap for lines and total; spoilage excluded
- [x] One pickup now writes all its sale rows under one transaction_id
- [ ] Not compiled yet: run `flutter analyze` and `flutter test`
- [x] Phase 7f: invoice list summary (money still open) and search by party or invoice number
- [ ] Known gap: a multi-line invoice save is not atomic (a failure partway leaves partial rows)

## Phase 8 - Backend wiring (written, not compiled)
- [x] Apps Script backend (see retail_backend_apps_script.zip): sign_in, invoice-level saves, atomic per request
- [x] HTTP client (lib/data/backend/backend_client.dart) and JSON mappers
- [x] HttpRetailRepository implements RetailRepository; MockRetailRepository has the same interface
- [x] Store: one snapshot call per reload; whole invoices saved in one call
- [x] Login checks the PIN on the server; logout clears the session and the store
- [x] Old tests moved to the new repository API
- [x] Set backend_url in lib/core/app_config.dart to the deployed /exec URL
- [x] Compiled: `flutter pub get`, `flutter analyze` and `flutter test` run, Riverpod test errors fixed
- [ ] Deployed: build release APK / web and publish (no CI configured yet)
- [ ] Field test against the live Apps Script backend (verify Apps Script Web App access is "Anyone")
