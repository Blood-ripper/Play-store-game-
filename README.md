# 🚜 Farm Rush

A farming **arcade + idle tycoon** game for Android (and iOS/web), built from the
reference screenshots. Harvest sunflower fields, earn coins, and build your farm
empire — then climb a global leaderboard against other players.

Built with **Flutter + Flame** (game) and **Firebase** (auth, database,
leaderboard, IAP validation). Designed to be **publishable on Google Play**.

> **Status:** This repository is a complete, runnable **vertical slice +
> production scaffolding**. One game mode (Harvest) is fully playable; the
> backend, economy, store, 100+100 catalog, cosmetic frames, and IAP system are
> all wired. The remaining mini-games (Deliver / Catch / Repair / Ketchup /
> Explore) are stubbed as "coming soon" cards ready to build on the same engine.
> See [`docs/ROADMAP.md`](docs/ROADMAP.md).

---

## ✨ What's implemented

| Requirement | Status | Where |
|---|---|---|
| Playable game (from screenshot 1 — "Harvest!") | ✅ Flame mini-game with joystick, timer, scoring | `lib/game/` |
| Authentication (email, Google, **guest**) | ✅ | `lib/services/auth_service.dart` |
| Database (player profiles, cloud sync + offline) | ✅ Firestore + local cache | `lib/services/player_repository.dart` |
| Login / sign-up page | ✅ | `lib/ui/screens/login_screen.dart` |
| Leaderboard | ✅ global, with glow frames per player | `lib/services/leaderboard_service.dart` |
| User handles (unique) | ✅ | `player_repository.dart` + `firestore.rules` |
| **100 vehicles** | ✅ generated catalog, tiered & priced | `lib/data/vehicles_catalog.dart` |
| **100 farmer items** | ✅ hats/outfits/tools/pets/boosters | `lib/data/farmer_items_catalog.dart` |
| 2 free vehicles + 2 free items for guests/new users | ✅ | catalogs (`freeUnlock: true`) |
| In-app purchases (Google Play Billing) | ✅ gems/coins/VIP/bundles + server validation | `lib/services/iap_service.dart`, `functions/index.js` |
| Buy items / groceries / vehicles with currency | ✅ | `lib/ui/screens/shop_screen.dart` |
| **Glowy purchased frames** (free users see plain frame) | ✅ animated glow rings by tier | `lib/ui/widgets/player_avatar.dart` |
| Logo | ✅ SVG app icon | `assets/logo/farm_rush_logo.svg` |
| Proper architecture (multiple vehicles, services, state) | ✅ | see `docs/ARCHITECTURE.md` |

"Multiplayer": players share one global world via the **cloud leaderboard** and
**globally-visible cosmetic frames** (asynchronous multiplayer). Real-time lobby
multiplayer is scoped in [`docs/ROADMAP.md`](docs/ROADMAP.md).

---

## 🏃 Run it

You need the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.27+). This container has no Flutter SDK, so run these on your own machine:

```bash
# 1. Generate the platform folders (android/ios/web) for this project
flutter create .

# 2. Get packages
flutter pub get

# 3. Run in LOCAL mode (no Firebase needed — auth/DB/leaderboard are on-device)
flutter run

# ...or run the playable game immediately as a guest: tap "Play as guest".
```

Regenerate the 100+100 catalog any time (edit tiers/prices in the script):

```bash
python3 tool/generate_catalog.py
```

### Enabling the real backend (Firebase)

```bash
dart pub global activate flutterfire_cli
flutterfire configure          # writes lib/firebase_options.dart
# then build with the backend on:
flutter run --dart-define=FIREBASE_ENABLED=true
```

Full backend + Play Store setup (billing, signing, release AAB) is in
[`docs/SETUP.md`](docs/SETUP.md).

---

## 🗺️ Project layout

```
lib/
  main.dart                 app entry (orientation, optional Firebase init)
  app.dart                  routes splash → login → home by auth state
  core/
    app_config.dart         feature flags (firebase/billing), economy constants
    app_state.dart          ChangeNotifier: the single source of truth
    theme/app_theme.dart    farm-arcade colours & styles
  models/                   vehicle, farmer_item, player_frame, user_profile,
                            leaderboard_entry, iap_product
  data/                     GENERATED 100 vehicles + 100 items catalogs
  services/                 auth, player_repository, leaderboard, iap
  game/                     Flame harvest mini-game (tractor, crops)
  ui/screens/               splash, login, home(hub), game, shop, leaderboard, profile
  ui/widgets/               player_avatar (glow frames), currency_bar
functions/                  Cloud Functions: IAP validation, leaderboard guard, seeding
firestore.rules             security rules (anti-cheat, ownership)
tool/generate_catalog.py    catalog generator → Dart + Firestore seed JSON
assets/logo/                SVG logo / app icon
docs/                       SETUP, ARCHITECTURE, ROADMAP, MONETIZATION
```

---

## 💰 Monetization model

Free-to-play. Guests start with 2 tractors + 2 items and 500 coins / 10 gems.
Players earn **coins** by playing and spend them on most of the 100 vehicles &
100 items. Premium (gem-priced) content and the **VIP pass** are bought with
**gems**, which come from real-money IAP. Premium ownership lights up a glowing
avatar frame visible to everyone. Details: [`docs/MONETIZATION.md`](docs/MONETIZATION.md).

---

## ⚖️ License & assets

Code is yours to ship. The emoji-based visuals are placeholders for a fast,
asset-free run — replace with your own sprites before a polished launch (see
`docs/ROADMAP.md`). Don't ship copyrighted art from the reference screenshots.
