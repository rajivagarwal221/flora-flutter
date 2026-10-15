# Flora - Flower Shop Management App

Full-parity Android port of the Sidhi Florals web app, sharing the same Supabase backend.

## What's inside

- **Dashboard** — today & monthly stats, revenue trend, star product, low stock, unavailable bouquets
- **Billing** — POS catalog, custom bouquet builder, cart, customer picker, total / amount paid, generate bill → receipt
- **Sales ledger** — all bills, expand to see line items, void (returns stock)
- **Inventory** — Stock / Bouquets / Margins tabs; add/edit/archive products; edit bouquet recipes
- **Customers** — list, create, edit, archive, purchase history sheet
- **Credits & dues** — outstanding bills, record payment
- **Reports** — monthly revenue, daily units, daily profit, monthly profit, top products
- **Receipt sheet** — formatted bill + Print / PDF export via the system print dialog

Supabase URL & anon key are read from `--dart-define` with sensible defaults in `lib/config.dart`.

## Build

Prereqs:

1. **Android Studio** (installs Android SDK, platform tools, emulator). After installing, open it once and let it finish SDK setup, then:
   ```
   flutter doctor --android-licenses
   ```
2. From this folder:
   ```
   flutter pub get
   flutter run              # on a connected phone or emulator
   flutter build apk --release
   ```
   The release APK lands at `build/app/outputs/flutter-apk/app-release.apk`.

### Override Supabase creds at build time

```
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

## Project layout

```
lib/
  main.dart            app entry + go_router
  config.dart          Supabase URL / anon key
  theme.dart           colors + Material 3 theme
  utils.dart           currency, dates, display helpers
  shell.dart           bottom nav scaffold
  data/
    models.dart        Dart mirrors of src/api/types.ts
    api.dart           PostgREST client (http) + Repo
  screens/             one file per page
  widgets/             async view, receipt sheet (with PDF)
```
