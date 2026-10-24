/**
 * Farm Rush Cloud Functions.
 *
 * Responsibilities:
 *   1. verifyPurchase  — validates a Google Play purchase token server-side
 *                        and grants gems / coins / VIP to the player. Clients
 *                        are NEVER trusted to grant their own premium currency.
 *   2. onScoreWrite    — clamps / sanitises leaderboard scores (anti-cheat).
 *   3. getLeaderboard  — convenience callable returning the top N.
 *
 * Product -> grant mapping must match lib/models/iap_product.dart.
 */

const admin = require("firebase-admin");
const functions = require("firebase-functions");
const { google } = require("googleapis");

admin.initializeApp();
const db = admin.firestore();

// Keep in sync with lib/models/iap_product.dart
const PRODUCTS = {
  "farmrush.gems.handful": { gems: 50, coins: 0, vip: false, consumable: true },
  "farmrush.gems.sack": { gems: 300, coins: 2000, vip: false, consumable: true },
  "farmrush.gems.wagon": { gems: 800, coins: 6000, vip: false, consumable: true },
  "farmrush.coins.chest": { gems: 0, coins: 10000, vip: false, consumable: true },
  "farmrush.vip.pass": { gems: 200, coins: 0, vip: true, consumable: false },
  "farmrush.bundle.starter": { gems: 150, coins: 5000, vip: false, consumable: true },
};

const ANDROID_PACKAGE = "com.farmrush.game";

/**
 * Validate a purchase with the Google Play Developer API and grant currency.
 * Called from the client after a successful in_app_purchase flow with the
 * productId and purchaseToken.
 */
exports.verifyPurchase = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = context.auth.uid;
  const { productId, purchaseToken } = data || {};
  const product = PRODUCTS[productId];
  if (!product) {
    throw new functions.https.HttpsError("invalid-argument", "Unknown product.");
  }

  // Idempotency: never grant the same token twice.
  const receiptRef = db.collection("receipts").doc(purchaseToken);
  const already = await receiptRef.get();
  if (already.exists) {
    return { ok: true, duplicate: true };
  }

  // Verify the token with Google Play. Requires a service account with the
  // "androidpublisher" scope (see docs/SETUP.md). Skipped if not configured
  // so the function still works in the emulator.
  if (process.env.PLAY_VERIFY === "true") {
    const auth = new google.auth.GoogleAuth({
      scopes: ["https://www.googleapis.com/auth/androidpublisher"],
    });
    const androidpublisher = google.androidpublisher({ version: "v3", auth });
    const resource = product.consumable ? "products" : "subscriptions";
    try {
      const res = await androidpublisher.purchases[resource].get({
        packageName: ANDROID_PACKAGE,
        productId,
        token: purchaseToken,
      });
      // purchaseState 0 = purchased
      if (res.data.purchaseState !== 0) {
        throw new functions.https.HttpsError(
          "failed-precondition", "Purchase not in a granted state.");
      }
    } catch (e) {
      throw new functions.https.HttpsError(
        "permission-denied", "Play verification failed: " + e.message);
    }
  }

  // Grant atomically.
  const playerRef = db.collection("players").doc(uid);
  await db.runTransaction(async (txn) => {
    const snap = await txn.get(playerRef);
    const cur = snap.data() || {};
    txn.set(
      playerRef,
      {
        gems: (cur.gems || 0) + product.gems,
        coins: (cur.coins || 0) + product.coins,
        vip: cur.vip || product.vip,
      },
      { merge: true }
    );
    txn.set(receiptRef, {
      uid,
      productId,
      grantedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true, granted: product };
});

/**
 * Sanitise leaderboard writes. Caps absurd scores and keeps the stored score
 * monotonically increasing. Runs on every write to /leaderboard/{uid}.
 */
exports.onScoreWrite = functions.firestore
  .document("leaderboard/{uid}")
  .onWrite(async (change, context) => {
    const after = change.after.exists ? change.after.data() : null;
    if (!after) return null;

    const MAX = 10000000;
    const score = Math.min(Math.max(0, Number(after.score) || 0), MAX);

    const before = change.before.exists ? change.before.data() : {};
    const prev = Number(before.score) || 0;
    const final = Math.max(prev, score);

    if (final !== after.score) {
      return change.after.ref.set({ score: final }, { merge: true });
    }
    return null;
  });

/** Top-N leaderboard as a callable (handy for web clients). */
exports.getLeaderboard = functions.https.onCall(async (data) => {
  const limit = Math.min(Number(data?.limit) || 50, 200);
  const snap = await db
    .collection("leaderboard")
    .orderBy("score", "desc")
    .limit(limit)
    .get();
  return snap.docs.map((d, i) => ({ rank: i + 1, ...d.data() }));
});
