const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");

initializeApp();
const db = getFirestore();

/**
 * Scheduled daily reset — runs every day at 00:00 Turkey time.
 * Creates a new empty dailyLog for each user and resets daily fields.
 */
exports.scheduledDailyReset = onSchedule(
  { schedule: "0 0 * * *", timeZone: "Europe/Istanbul" },
  async () => {
    const usersSnapshot = await db.collection("users").get();
    const batch = db.batch();
    const today = new Date().toISOString().split("T")[0];

    for (const userDoc of usersSnapshot.docs) {
      const logRef = userDoc.ref.collection("dailyLogs").doc(today);
      batch.set(logRef, {
        date: today,
        stepCount: 0,
        caloriesConsumed: 0,
        caloriesBurned: 0,
        waterGlasses: 0,
        mood: "",
        completedTasks: [],
        dailyScore: 0,
        xpEarned: 0,
        mealsLogged: 0,
      });
    }

    await batch.commit();
    console.log(`Daily reset completed for ${usersSnapshot.size} users.`);
  }
);

/**
 * Triggered when a new meal is saved.
 * Awards XP and updates user stats.
 */
exports.onMealSaved = onDocumentCreated(
  "users/{userId}/meals/{mealId}",
  async (event) => {
    const userId = event.params.userId;
    const userRef = db.collection("users").doc(userId);

    await db.runTransaction(async (transaction) => {
      const userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;

      const userData = userDoc.data();
      const currentXp = userData.xp || 0;
      const newXp = currentXp + 15;

      const stats = userData.stats || {};
      const vitality = stats.vitality || 0;

      transaction.update(userRef, {
        xp: newXp,
        "stats.vitality": vitality + 2,
      });
    });
  }
);

/**
 * Callable function: update daily login streak.
 * Called from client on app open.
 */
exports.onUserDailyLogin = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Giriş yapılmamış.");
  }

  const uid = request.auth.uid;
  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) return;

    const userData = userDoc.data();
    const lastLogin = userData.lastLoginDate || "";
    const today = new Date().toISOString().split("T")[0];

    if (lastLogin === today) {
      return;
    }

    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split("T")[0];

    let newStreak;
    if (lastLogin === yesterdayStr) {
      newStreak = (userData.streakDays || 0) + 1;
    } else {
      newStreak = 1;
    }

    transaction.update(userRef, {
      streakDays: newStreak,
      lastLoginDate: today,
    });
  });

  return { success: true };
});
