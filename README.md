# Fresh Preorder (Flutter)

Progress checklist: see `PROGRESS.md`.

## Run it
```bash
flutter create --project-name retail_preorder_app --platforms=android,ios,web retail_app
cp -r pubspec.yaml analysis_options.yaml lib test PROGRESS.md retail_app/
rm -f retail_app/test/widget_test.dart
cd retail_app
flutter pub get
flutter analyze
flutter test
flutter run -d web-server   # or an emulator
```

## Before you test WhatsApp
Set your number in `lib/core/app_config.dart` (`retailer_whatsapp_no`).

## Demo logins (mock)
- Retailer: `1234` (placeholder screen until phase 3)
- Customer Maria: `1111`, customer James: `2222`

## Not verified
Written without a Flutter SDK, so nothing was compiled or run. Paste any
`flutter analyze` or `flutter test` error back and it will be fixed.
