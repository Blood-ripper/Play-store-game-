/**
 * Seeds Firestore with the vehicle & item catalogs so they can be served
 * remotely / live-tuned without an app update. The app also ships the same
 * data locally (lib/data/*.dart) so it works offline.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS=./service-account.json
 *   node seed/seed.js
 */
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

admin.initializeApp();
const db = admin.firestore();

async function seedCollection(name, file) {
  const rows = JSON.parse(fs.readFileSync(path.join(__dirname, file), "utf8"));
  let batch = db.batch();
  let n = 0;
  for (const row of rows) {
    batch.set(db.collection(name).doc(row.id), row);
    if (++n % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  await batch.commit();
  console.log(`Seeded ${rows.length} docs into ${name}`);
}

(async () => {
  await seedCollection("catalog_vehicles", "vehicles.json");
  await seedCollection("catalog_items", "farmer_items.json");
  console.log("Done.");
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
