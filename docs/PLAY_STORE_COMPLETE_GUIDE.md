# Farm Rush: Complete Google Play Store Publishing Guide

Every API, credential, account, and step — from zero to a live Play Store listing.

---

## Table of Contents

1. [Accounts You Need](#1-accounts-you-need)
2. [APIs to Enable](#2-apis-to-enable)
3. [Tools & SDKs to Install](#3-tools--sdks-to-install)
4. [Firebase Setup (Backend)](#4-firebase-setup-backend)
5. [Cloud Functions Deployment](#5-cloud-functions-deployment)
6. [Android Project Configuration](#6-android-project-configuration)
7. [App Signing (Keystore)](#7-app-signing-keystore)
8. [Google Play Console Setup](#8-google-play-console-setup)
9. [In-App Purchase Products](#9-in-app-purchase-products)
10. [Service Account for Receipt Validation](#10-service-account-for-receipt-validation)
11. [Build the Release AAB](#11-build-the-release-aab)
12. [Store Listing & Content Rating](#12-store-listing--content-rating)
13. [Testing Tracks](#13-testing-tracks)
14. [Production Launch](#14-production-launch)
15. [Post-Launch Checklist](#15-post-launch-checklist)

---

## 1. Accounts You Need

| # | Account | Cost | Where to Create | What It's For |
|---|---------|------|-----------------|---------------|
| 1 | **Google Account** | Free | https://accounts.google.com | Owns everything below |
| 2 | **Google Play Developer Account** | $25 one-time | https://play.google.com/console/signup | Publish apps to the Play Store |
| 3 | **Firebase Project** | Free (Spark plan) | https://console.firebase.google.com | Auth, Firestore, Cloud Functions |
| 4 | **Google Cloud Project** (auto-created with Firebase) | Free tier | https://console.cloud.google.com | APIs, service accounts |

### How to create each one

**Google Play Developer Account:**
1. Go to https://play.google.com/console/signup
2. Sign in with your Google Account
3. Accept the Developer Distribution Agreement
4. Pay the $25 registration fee
5. Complete your developer profile (name, address, phone — required by Google)
6. Identity verification takes 2-5 business days (you can set up everything else while waiting)

**Firebase Project:**
1. Go to https://console.firebase.google.com
2. Click "Create a project" (or "Add project")
3. Name it `farm-rush` (or any name)
4. Enable Google Analytics if you want (optional)
5. Click Create — this also creates a linked Google Cloud project

---

## 2. APIs to Enable

Go to https://console.cloud.google.com/apis/library for your Firebase-linked project.

| # | API Name | Where to Find It | Why Farm Rush Needs It |
|---|----------|-------------------|----------------------|
| 1 | **Android Device Verification** | Search "Android Device Verification" | SafetyNet / Play Integrity checks |
| 2 | **Google Play Android Developer API** | Search "Google Play Android Developer" | Server-side receipt validation (`functions/index.js` → `verifyPurchase`) |
| 3 | **Identity Toolkit API** | Auto-enabled by Firebase Auth | Email/password + Google sign-in |
| 4 | **Cloud Firestore API** | Auto-enabled by Firebase | Database |
| 5 | **Cloud Functions API** | Auto-enabled by Firebase | Cloud Functions |
| 6 | **Token Service API** | Auto-enabled by Firebase Auth | OAuth token refresh |

### How to enable an API
1. Open https://console.cloud.google.com
2. Select your Firebase project from the dropdown at the top
3. Go to **APIs & Services** → **Library**
4. Search the API name
5. Click it → Click **Enable**

**The critical one you must manually enable:** `Google Play Android Developer API` — this is what lets your Cloud Function validate purchases.

---

## 3. Tools & SDKs to Install

Run these on your development machine:

```bash
# 1. Flutter SDK (3.27+)
# Download from https://docs.flutter.dev/get-started/install
# Or via snap/brew:
snap install flutter --classic
# Verify:
flutter --version
flutter doctor

# 2. Android Studio (includes Android SDK)
# Download from https://developer.android.com/studio
# After install, open SDK Manager and install:
#   - Android SDK Platform 34 (or latest)
#   - Android SDK Build-Tools 34
#   - Android SDK Command-line Tools
#   - Android Emulator (for testing)

# 3. Java Development Kit (JDK 17)
sudo apt install openjdk-17-jdk
# Needed for: keytool (signing), Gradle builds

# 4. Firebase CLI
npm install -g firebase-tools
# Verify:
firebase --version

# 5. FlutterFire CLI
dart pub global activate flutterfire_cli
# Verify:
flutterfire --version

# 6. Node.js 18+ (for Cloud Functions)
# Already needed for Firebase CLI
node --version   # Should be 18+
```

### Verification checklist
```bash
flutter doctor -v     # Should show no red X for Android toolchain
firebase login        # Should authenticate your Google account
java -version         # Should show 17+
node --version        # Should show 18+
```

---

## 4. Firebase Setup (Backend)

### Step 4a: Configure Firebase for Android

```bash
cd /path/to/Play-store-game-

# Generate the android/ folder first
flutter create .

# Run FlutterFire — it writes firebase_options.dart + google-services.json
flutterfire configure
```

When `flutterfire configure` prompts you:
1. Select your Firebase project (the one you created in step 1)
2. Select **Android** as the platform
3. It asks for the Android package name — enter: `com.farmrush.game`
4. It generates:
   - `lib/firebase_options.dart` (Dart config)
   - `android/app/google-services.json` (Android config)
   Both are git-ignored for security.

### Step 4b: Enable Firebase services in the console

Go to https://console.firebase.google.com → your project:

**Authentication:**
1. Click **Authentication** → **Get started**
2. Click **Sign-in method** tab
3. Enable these providers (click each → toggle on → Save):
   - **Email/Password** (toggle on, leave "Email link" off)
   - **Google** (enter your support email, click Save)
   - **Anonymous** (toggle on — for guest play)

**Firestore Database:**
1. Click **Firestore Database** → **Create database**
2. Choose **Start in production mode** (our rules handle security)
3. Select a location closest to your users (e.g., `us-central1` for US, `europe-west1` for EU)
4. Click **Enable**

**Google Sign-In SHA fingerprint:**
```bash
# Get your debug SHA-1 (for testing)
cd android
./gradlew signingReport
# Copy the SHA-1 from the "debug" variant

# In Firebase Console → Project Settings → Your Apps → Android app
# Click "Add fingerprint" → paste the SHA-1
# You'll add the release SHA-1 later after creating your keystore
```

### Step 4c: Deploy Firestore rules and indexes

```bash
firebase login              # if not already logged in
firebase use --add          # select your project
firebase deploy --only firestore:rules,firestore:indexes
```

This deploys:
- `firestore.rules` → security rules (owner-only profiles, public leaderboard, create-only receipts)
- `firestore.indexes.json` → composite indexes for leaderboard queries

---

## 5. Cloud Functions Deployment

### Step 5a: Install and deploy

```bash
cd functions
npm install           # installs firebase-functions, firebase-admin, googleapis

cd ..
firebase deploy --only functions
```

This deploys three functions:
| Function | Type | Purpose |
|----------|------|---------|
| `verifyPurchase` | HTTPS Callable | Validates Play Store purchase tokens, grants gems/coins/VIP |
| `onScoreWrite` | Firestore Trigger | Clamps scores to 10M, enforces monotonic increase (anti-cheat) |
| `getLeaderboard` | HTTPS Callable | Returns top N leaderboard entries |

### Step 5b: Seed the catalog (optional)

```bash
cd functions

# You need a service account key for this
# (see Step 10 for how to create one)
export GOOGLE_APPLICATION_CREDENTIALS=./service-account.json
node seed/seed.js
```

This writes the 100 vehicles + 100 items to Firestore so the server has the canonical catalog. The app also ships them locally in `lib/data/`.

---

## 6. Android Project Configuration

### Step 6a: Set the application ID

After `flutter create .`, edit `android/app/build.gradle` (or `build.gradle.kts`):

```gradle
android {
    namespace = "com.farmrush.game"
    
    defaultConfig {
        applicationId = "com.farmrush.game"
        minSdk = 23        // Android 6.0 — covers 97%+ of devices
        targetSdk = 34     // Android 14 — Play Store requires latest
        versionCode = 1
        versionName = "1.0.0"
    }
}
```

**IMPORTANT:** The `applicationId` must be unique on the Play Store and must EXACTLY match:
- `ANDROID_PACKAGE` in `functions/index.js` (`"com.farmrush.game"`)
- What you register in Play Console

### Step 6b: Add the billing permission

Edit `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:

```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

### Step 6c: Set internet permission (usually auto-added)

Verify this exists in the manifest:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### Step 6d: App icon

```bash
# Add flutter_launcher_icons to dev_dependencies in pubspec.yaml
# Then in pubspec.yaml:
flutter_launcher_icons:
  android: true
  image_path: "assets/logo/farm_rush_logo.png"  # convert SVG to PNG first

# Run:
dart run flutter_launcher_icons
```

Or manually place PNGs in `android/app/src/main/res/mipmap-*` directories.

---

## 7. App Signing (Keystore)

### Step 7a: Generate the keystore

```bash
keytool -genkey -v \
  -keystore ~/farmrush.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias farmrush
```

It will prompt for:
- **Keystore password** — pick a strong one, WRITE IT DOWN (lost = can never update the app)
- **Key password** — can be the same
- **Name, Org, City, State, Country** — fill in your info

### Step 7b: Create `android/key.properties`

Create `android/key.properties` (this file is git-ignored):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=farmrush
storeFile=/path/to/farmrush.jks
```

### Step 7c: Wire signing into Gradle

Edit `android/app/build.gradle`:

```gradle
// At the top, before android {}
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ...existing config...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Step 7d: Get your release SHA-1 and add to Firebase

```bash
keytool -list -v -keystore ~/farmrush.jks -alias farmrush
# Copy the SHA-1 fingerprint
# Go to Firebase Console → Project Settings → Android app → Add fingerprint
```

---

## 8. Google Play Console Setup

### Step 8a: Create the app

1. Go to https://play.google.com/console
2. Click **Create app**
3. Fill in:
   - **App name:** Farm Rush
   - **Default language:** English (United States)
   - **App or game:** Game
   - **Free or paid:** Free
4. Accept the declarations → **Create app**

### Step 8b: Complete the store listing (required before any upload)

Go to **Grow** → **Store listing** → **Main store listing**:

| Field | What to Enter |
|-------|---------------|
| **App name** | Farm Rush |
| **Short description** | Drive your tractor, harvest crops, compete on the leaderboard! (max 80 chars) |
| **Full description** | A fun farming arcade game. Drive 100+ unique vehicles across sunflower fields... (max 4000 chars) |
| **App icon** | 512x512 PNG, the farm_rush_logo |
| **Feature graphic** | 1024x500 PNG (banner shown at top of listing) |
| **Phone screenshots** | At least 2, recommended 4-8 (from your 8 reference screenshots) |
| **Tablet screenshots** | Optional but recommended |

### Step 8c: Content rating questionnaire

Go to **Policy** → **App content** → **Content rating**:

1. Click **Start questionnaire**
2. Category: **Games** → **All other game types**
3. Answer honestly:
   - Violence: No (crop harvesting is not violence)
   - Sexual content: No
   - Language: No
   - Controlled substances: No
   - In-app purchases: **Yes** (this is important!)
4. Submit → you get a rating (likely **Everyone / PEGI 3**)

### Step 8d: Privacy policy

**Required** because Farm Rush collects:
- Account data (email for auth)
- Purchase history (IAP receipts)

You must host a privacy policy at a public URL. Minimum content:
- What data you collect (email, game progress, purchase records)
- How you use it (authentication, leaderboard, purchase verification)
- Third parties (Firebase/Google)
- How to contact you
- How to request data deletion

Add the URL in **Policy** → **App content** → **Privacy policy**.

### Step 8e: Data safety form

Go to **Policy** → **App content** → **Data safety**:

| Data type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| Email address | Yes | No | Account management |
| User IDs | Yes | No | App functionality |
| Purchase history | Yes | No | App functionality |
| Game progress | Yes | No | App functionality |
| Other app performance data | Yes | No | Analytics |

### Step 8f: Ads declaration

Go to **Policy** → **App content** → **Ads**: Select **No, my app does not contain ads**.

### Step 8g: Target audience

Go to **Policy** → **App content** → **Target audience and content**:
- Target age group: **13+** or **All ages** (if no chat/social features)
- Is it designed for children: **No** (avoids COPPA requirements)

### Step 8h: Government apps and News

Mark both as **No** in **App content**.

---

## 9. In-App Purchase Products

### Step 9a: Upload an AAB first

Google Play requires at least one uploaded AAB/APK before you can create products.
Build and upload an internal test build first (see Step 11), then come back here.

### Step 9b: Create managed products

Go to **Monetize** → **Products** → **In-app products** → **Create product**:

| # | Product ID (exact) | Name | Price | Type |
|---|-------------------|------|-------|------|
| 1 | `farmrush.gems.handful` | Handful of Gems | $0.99 | Managed (consumable) |
| 2 | `farmrush.gems.sack` | Sack of Gems | $4.99 | Managed (consumable) |
| 3 | `farmrush.gems.wagon` | Wagon of Gems | $9.99 | Managed (consumable) |
| 4 | `farmrush.coins.chest` | Coin Chest | $2.99 | Managed (consumable) |
| 5 | `farmrush.bundle.starter` | Starter Tycoon Bundle | $3.99 | Managed (consumable) |
| 6 | `farmrush.vip.pass` | VIP Farmer Pass | $6.99 | Managed (non-consumable) OR Subscription |

For each product:
1. Click **Create product**
2. **Product ID:** enter the exact `storeId` from above (cannot be changed later!)
3. **Name:** display name
4. **Description:** what the user gets
5. **Default price:** set the price → **Apply**
6. **Status:** change to **Active**

**WARNING:** Product IDs are permanent. Double-check they match `lib/models/iap_product.dart` exactly.

### Step 9c: Set up license testers

Go to **Settings** → **License testing**:
1. Add your own Gmail address and any testers' emails
2. License response: **RESPOND_NORMALLY** (for testing real flows) or **LICENSED** (always grants)
3. These accounts can "buy" without being charged

---

## 10. Service Account for Receipt Validation

This lets `functions/index.js` → `verifyPurchase` validate purchase tokens with Google.

### Step 10a: Create a service account

1. Go to https://console.cloud.google.com/iam-admin/serviceaccounts
2. Select your Firebase project
3. Click **Create Service Account**
4. Name: `play-verification`
5. Description: "Validates Play Store purchase receipts"
6. Click **Create and Continue**
7. Skip the optional role grants → **Done**

### Step 10b: Generate a JSON key

1. Click the service account you just created
2. Go to **Keys** tab → **Add Key** → **Create new key**
3. Select **JSON** → **Create**
4. A `.json` file downloads — this is your secret. Keep it safe.

### Step 10c: Link the service account to Play Console

1. Go to https://play.google.com/console
2. Click **Settings** → **API access**
3. Link to your Google Cloud project (it should auto-detect)
4. Under **Service accounts**, find `play-verification`
5. Click **Grant access** → set permission to **View financial data** and **Manage orders and subscriptions**
6. Click **Invite user** → **Send invitation**

### Step 10d: Deploy the key to Firebase Functions

```bash
# Set the environment variable for the function
firebase functions:config:set play.verify="true"

# OR use the newer secrets approach:
firebase functions:secrets:set PLAY_VERIFY
# Enter: true

# Deploy the service account key as a secret or place it where
# the function can read it. The googleapis library uses
# Application Default Credentials, so set:
# GOOGLE_APPLICATION_CREDENTIALS pointing to the key file
# OR deploy the function with the service account identity.
```

The simplest approach for production:
```bash
# In your functions directory, set the runtime service account:
# firebase.json → functions → serviceAccount (or use the default one
# and grant it the androidpublisher scope)
```

---

## 11. Build the Release AAB

### Step 11a: Build

```bash
cd /path/to/Play-store-game-

# Make sure android/ exists
flutter create .
flutter pub get

# Build the release Android App Bundle
flutter build appbundle \
  --dart-define=FIREBASE_ENABLED=true \
  --dart-define=BILLING_ENABLED=true

# Output file:
# build/app/outputs/bundle/release/app-release.aab
```

### Step 11b: Verify before uploading

```bash
# Check the AAB is signed
jarsigner -verify build/app/outputs/bundle/release/app-release.aab

# Test locally first
flutter run --release \
  --dart-define=FIREBASE_ENABLED=true \
  --dart-define=BILLING_ENABLED=true
```

---

## 12. Store Listing & Content Rating

Make sure these are ALL completed before trying to publish:

### Required checklist (all in Play Console)

- [ ] App name, short description, full description
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG)
- [ ] At least 2 phone screenshots (16:9 or 9:16)
- [ ] Content rating questionnaire completed
- [ ] Privacy policy URL set
- [ ] Data safety form completed
- [ ] Target audience selected
- [ ] Ads declaration done
- [ ] App category: **Game** → **Arcade** (or **Simulation**)
- [ ] Contact details: email (required), phone (optional), website (optional)

---

## 13. Testing Tracks

### Step 13a: Internal testing (recommended first)

1. Go to **Testing** → **Internal testing**
2. Click **Create new release**
3. If prompted about Play App Signing, **opt in** (recommended — Google manages your key)
4. Upload `app-release.aab`
5. Add release notes (e.g., "Initial internal test")
6. Click **Review release** → **Start rollout to Internal testing**

### Step 13b: Add testers

1. In Internal testing → **Testers** tab
2. Create an email list with your testers' Gmail addresses
3. Copy the **opt-in URL** and send it to each tester
4. They click the link → install from Play Store

### Step 13c: Closed testing (optional — wider audience)

Same process, under **Testing** → **Closed testing**. Good for beta with 100+ testers.

### Step 13d: Open testing (optional — public beta)

Under **Testing** → **Open testing**. Anyone can join.

### Test IAP purchases

1. Make sure tester emails are in **Settings** → **License testing**
2. Install the app from the Play Store (not sideloaded)
3. Purchases will show the real flow but won't charge money

---

## 14. Production Launch

### Step 14a: Pre-launch report

After uploading to Internal testing, check **Quality** → **Pre-launch report**. Google runs automated testing on real devices. Fix any crashes.

### Step 14b: Promote to production

1. Go to **Production** → **Create new release** (or promote from a testing track)
2. Upload the AAB (or promote the same one from internal)
3. Add release notes for users
4. Set rollout percentage (start at 20% if nervous, or 100%)
5. Click **Review release** → **Start rollout to Production**

### Step 14c: Review process

- Google reviews the app (usually 1-7 days for new apps)
- You'll get an email when approved or if rejected
- Common rejection reasons:
  - Missing privacy policy
  - Incomplete data safety form
  - App crashes on launch
  - In-app purchases not working
  - Content rating missing

---

## 15. Post-Launch Checklist

### Monitoring

| What | Where | Why |
|------|-------|-----|
| Crash reports | Firebase Crashlytics (add the dependency) | Fix crashes fast |
| Revenue | Play Console → Financial reports | Track IAP income |
| Ratings & reviews | Play Console → Ratings | Respond to users |
| Function errors | Firebase Console → Functions → Logs | Monitor `verifyPurchase` failures |
| Active users | Firebase Analytics | Track engagement |

### Recommended additions after launch

```yaml
# Add to pubspec.yaml for production readiness:
firebase_crashlytics: ^3.5.7   # Crash reporting
firebase_analytics: ^10.10.7    # Usage analytics
firebase_remote_config: ^4.4.7  # Feature flags
```

### Update workflow

```bash
# Bump version in pubspec.yaml
version: 1.1.0+2    # versionName+versionCode (code must always increment)

# Build
flutter build appbundle \
  --dart-define=FIREBASE_ENABLED=true \
  --dart-define=BILLING_ENABLED=true

# Upload to Play Console → Production → Create new release
```

---

## Quick Reference: All Credentials & Secrets

| Secret | Where It Lives | Git-Ignored? |
|--------|---------------|-------------|
| `google-services.json` | `android/app/` | Yes |
| `firebase_options.dart` | `lib/` | Yes |
| `farmrush.jks` (keystore) | `~/` (your home) | Not in repo |
| `key.properties` | `android/` | Yes |
| Service account JSON | `functions/` or GCP | Yes |
| Keystore password | Your password manager | N/A |

**NEVER commit secrets to git.** The `.gitignore` already excludes them.

---

## Quick Reference: All URLs You Need

| Resource | URL |
|----------|-----|
| Play Console | https://play.google.com/console |
| Firebase Console | https://console.firebase.google.com |
| Google Cloud Console | https://console.cloud.google.com |
| GCP API Library | https://console.cloud.google.com/apis/library |
| GCP IAM (Service Accounts) | https://console.cloud.google.com/iam-admin/serviceaccounts |
| Flutter Install Guide | https://docs.flutter.dev/get-started/install |
| Flutter Android Deployment | https://docs.flutter.dev/deployment/android |
| Play Billing Docs | https://developer.android.com/google/play/billing |
| Firebase Auth Docs | https://firebase.google.com/docs/auth |
| Firestore Docs | https://firebase.google.com/docs/firestore |
| Cloud Functions Docs | https://firebase.google.com/docs/functions |

---

## Estimated Timeline

| Phase | Time | What |
|-------|------|------|
| Accounts & setup | 1-2 hours | Create accounts, enable APIs |
| Firebase config | 30 min | `flutterfire configure`, deploy rules |
| Cloud Functions | 15 min | `firebase deploy --only functions` |
| Signing | 15 min | Generate keystore, wire Gradle |
| First build & upload | 30 min | Build AAB, upload to internal |
| Store listing | 1-2 hours | Screenshots, descriptions, privacy policy |
| IAP products | 30 min | Create 6 products in Play Console |
| Service account | 30 min | Create, link, deploy key |
| Testing | 1-3 days | Internal testers verify everything works |
| Review | 1-7 days | Google reviews the app |
| **Total** | **~1-2 weeks** | From start to live on Play Store |
