# Setup & Google Play publishing guide

This takes Farm Rush from the repo to a signed release on the Play Store.
Steps that only *you* can do (they need your accounts / keys) are marked 🔑.

## 0. Prerequisites

- Flutter SDK 3.27+ and Android Studio (or just the Android SDK + cmdline-tools).
- A Google account.
- 🔑 A **Google Play Developer account** ($25 one-time) — https://play.google.com/console
- 🔑 A **Firebase project** — https://console.firebase.google.com

## 1. Generate platform folders

The repo intentionally does not commit `android/` (it's generated). From the
project root:

```bash
flutter create .
flutter pub get
```

## 2. Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure          # select/create your Firebase project
```

This writes `lib/firebase_options.dart` and `android/app/google-services.json`
(both git-ignored). In the Firebase console enable:

- **Authentication** → Sign-in methods: Email/Password, Google, **Anonymous**.
- **Firestore Database** → create in production mode.
- Deploy rules & indexes:

```bash
npm i -g firebase-tools
firebase login
firebase deploy --only firestore:rules,firestore:indexes
```

Turn the backend on at build time:

```bash
flutter run --dart-define=FIREBASE_ENABLED=true
```

## 3. Cloud Functions (IAP validation + leaderboard guard)

```bash
cd functions
npm install
firebase deploy --only functions
```

🔑 For real Play receipt validation, create a service account with the
**Android Publisher** API enabled, link it in Play Console
(*Users and permissions* → *API access*), and set `PLAY_VERIFY=true` in the
function's environment. Without it, grants still work for testing.

Seed the catalogs to Firestore (optional — the app also ships them locally):

```bash
cd functions
export GOOGLE_APPLICATION_CREDENTIALS=./service-account.json
node seed/seed.js
```

## 4. Android: application id, billing permission, icon

In `android/app/build.gradle` (or `build.gradle.kts`):

```gradle
android {
    namespace = "com.farmrush.game"
    defaultConfig {
        applicationId = "com.farmrush.game"   // must match functions/index.js ANDROID_PACKAGE
        minSdk = 23
        targetSdk = 34
    }
}
```

Add the billing permission to `android/app/src/main/AndroidManifest.xml`,
inside `<manifest>` (the `in_app_purchase` plugin needs it):

```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

App icon: convert `assets/logo/farm_rush_logo.svg` to PNG and use
[`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons),
or drop PNGs into `android/app/src/main/res/mipmap-*`.

## 5. In-app products (Play Console)

🔑 Monetize → Products → **In-app products** (and **Subscriptions** for VIP if
you prefer a sub). Create one product per entry in
`lib/models/iap_product.dart`, using the **exact** `storeId`:

| storeId | type |
|---|---|
| `farmrush.gems.handful` | consumable |
| `farmrush.gems.sack` | consumable |
| `farmrush.gems.wagon` | consumable |
| `farmrush.coins.chest` | consumable |
| `farmrush.bundle.starter` | consumable |
| `farmrush.vip.pass` | non-consumable (or subscription) |

Add testers under *License testing* so purchases don't charge real money.
Enable billing at build time: `--dart-define=BILLING_ENABLED=true`.

## 6. Sign the release 🔑

```bash
keytool -genkey -v -keystore ~/farmrush.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias farmrush
```

Create `android/key.properties` (git-ignored) and wire it in
`android/app/build.gradle` `signingConfigs` per the
[Flutter deployment docs](https://docs.flutter.dev/deployment/android#signing-the-app).

## 7. Build & upload

```bash
flutter build appbundle \
  --dart-define=FIREBASE_ENABLED=true \
  --dart-define=BILLING_ENABLED=true
# output: build/app/outputs/bundle/release/app-release.aab
```

Upload the `.aab` to Play Console → *Testing* → *Internal testing* first.
Complete the store listing (icon, screenshots, privacy policy — required
because the app collects accounts), then promote to Production.

## Troubleshooting

- **Purchases don't grant in release:** confirm `storeId`s match exactly and the
  app is signed with the same key uploaded to Play.
- **Leaderboard empty in LOCAL mode:** it self-seeds; pull-to-refresh.
- **Google sign-in fails:** add your SHA-1/SHA-256 to the Firebase Android app
  (`./gradlew signingReport`).
