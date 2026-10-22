# Flora · Flower Shop Management

Flutter app for billing, inventory, customers, dues, reports, and planning. It uses Firebase project `flora-411ad` for Authentication and Firestore.

## What is available

- **Billing and dues:** receipts, stock deduction, payment recording, and voids use Firestore transactions.
- **Inventory:** products and bouquet recipes, with separate receipt, waste, adjustment, and stock history records.
- **Reports:** one date range for revenue, profit, units, and product charts. The category pie chart has a custom bouquet slice and product drill-down. Voided bills are excluded.
- **Planning:** weekly sales changes, overdue amounts, reorder proposals, bouquet ideas, days of stock left, and seven-day demand ranges with a prior-week comparison. These are deterministic calculations over shop data. Proposals require manual action; they never edit stock or prices.

## Firebase setup

The Android and web app identifiers are in `lib/firebase_options.dart`. The Android app is registered with package `com.sidhiflorals.sidhi_florals`. Google sign-in and Firestore rules are managed in `firebase.json` and `firestore.rules`.

Firestore currently allows access only to the verified Google account named in `firestore.rules`. Edit that account and redeploy rules when ownership changes. A different release signing key needs its SHA-1 and SHA-256 fingerprints registered in the Firebase Android app.

The one-time data import from the former backend was completed on 2026-10-22 and verified by counts: 1 product, 1 customer, 8 sales. The running Flutter app has no Supabase connection. The separate web app has not been migrated here.

## Run

Install Flutter and the Android SDK, then run:

```text
flutter pub get
flutter run
```

For Android:

```text
flutter build apk --release
```

The release build currently uses the standard debug signing key. Register a production signing key with Firebase before distributing a production APK.

To redeploy backend configuration:

```text
npx -y firebase-tools@latest deploy --only firestore:rules,auth --project flora-411ad
```

Web Google sign-in works on authorized Firebase domains. Add a deployed web domain in Firebase Authentication settings if hosting the Flutter web build elsewhere.
