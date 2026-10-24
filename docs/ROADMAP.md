# Roadmap

What's done (this repo) vs. what remains to a polished Play Store launch.

## ✅ Done — playable slice + full scaffolding
- Harvest mini-game (Flame): joystick, scoring, timer, results, coin rewards.
- Auth: email / Google / guest, with local fallback.
- Profiles in Firestore + offline cache; unique handles.
- Global leaderboard with per-player glow frames.
- 100 vehicles + 100 items catalog (2 + 2 free), data-driven.
- Shop: buy with coins/gems; equip vehicles & frames.
- IAP: 6 products, Play Billing flow, server-side validation Cloud Function.
- Cosmetic glow-frame system (free = plain, premium/VIP = animated glow).
- Security rules + anti-cheat score clamping.
- Logo, theme, docs.

## 🔜 Next — the other reference screens (same engine pattern)
Each is a new `FlameGame` + hub card + route. Estimated effort each: 1–3 days.
1. **Deliver Orders** (screenshot 2): match produce to customer requests; combo timer.
2. **Catch!** (screenshot 3): water-spray to catch escaping crops; reflex scoring.
3. **Repair Barn** (screenshot 4): tap-to-build upgrade mini-game.
4. **Ketchup Factory** (screenshot 5): tomato → bottle production/idle line.
5. **Explore Island** (screenshot 6): tile-reveal exploration; new crops/biomes.
6. **Animal Pens** (screenshot 7): cows/sheep/chickens idle producers.

## 🔜 Real-time multiplayer (currently asynchronous)
- Co-op harvest lobbies (Firestore Realtime or a lightweight game server).
- Friends list + weekly seasonal leaderboards.
- Live ghost tractors from other players.

## 🎨 Art & polish
- Replace emoji placeholders with sprite sheets (tractors, crops, UI).
- Convert the SVG logo to launcher PNGs via `flutter_launcher_icons`.
- Sound FX + music; haptics on harvest.
- Onboarding tutorial on first launch.

## 🧪 Quality before launch
- Expand tests (unit for `AppState` economy, widget for shop/frames).
- Crash reporting (Firebase Crashlytics) + analytics.
- Privacy policy + Play Data Safety form (app collects accounts & purchases).
