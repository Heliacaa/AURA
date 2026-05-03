const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

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
        sleepHours: 0,
        sleepQuality: "",
        claimedQuestIds: [],
      });
    }

    await batch.commit();
    console.log(`Daily reset completed for ${usersSnapshot.size} users.`);
  }
);

/**
 * Triggered when a new meal is saved.
 * XP is awarded by the Flutter client so quest/weekly XP stays consistent.
 */
exports.onMealSaved = onDocumentCreated(
  "users/{userId}/meals/{mealId}",
  async (event) => {
    console.log(`Meal XP trigger skipped for ${event.params.userId}.`);
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

/**
 * Scheduled coaching check — runs every day at 20:00 Turkey time.
 * Sends motivational push notifications to users who are behind on goals.
 */
exports.scheduledCoachingCheck = onSchedule(
  { schedule: "0 20 * * *", timeZone: "Europe/Istanbul" },
  async () => {
    const usersSnapshot = await db.collection("users").get();
    const today = new Date().toISOString().split("T")[0];
    const messaging = getMessaging();
    let sent = 0;

    for (const userDoc of usersSnapshot.docs) {
      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;
      if (!fcmToken) continue;

      const goals = userData.dailyGoals || {};
      const logDoc = await userDoc.ref.collection("dailyLogs").doc(today).get();
      if (!logDoc.exists) continue;

      const log = logDoc.data();
      const messages = [];

      // Check steps
      const stepGoal = goals.steps || 10000;
      const steps = log.stepCount || 0;
      if (steps < stepGoal * 0.5) {
        messages.push(`Bugün henüz ${steps} adım attın, hedefin ${stepGoal}. Kısa bir yürüyüşe ne dersin?`);
      }

      // Check water
      const waterGoal = goals.water || 8;
      const water = log.waterGlasses || 0;
      if (water < waterGoal * 0.5) {
        messages.push(`Henüz ${water} bardak su içtin, hedefin ${waterGoal}. Su içmeyi unutma!`);
      }

      // Check calories
      const calGoal = goals.calories || 2000;
      const consumed = log.caloriesConsumed || 0;
      if (consumed === 0) {
        messages.push("Bugün henüz yemek kaydetmedin. Yemeklerini taramayı unutma!");
      }

      if (messages.length > 0) {
        try {
          await messaging.send({
            token: fcmToken,
            notification: {
              title: "AURA Koçun Hatırlatıyor 🌟",
              body: messages[0],
            },
            data: {
              type: "coaching",
            },
          });
          sent++;
        } catch (e) {
          console.log(`Failed to send to ${userDoc.id}:`, e.message);
        }
      }
    }

    console.log(`Coaching notifications sent to ${sent} users.`);
  }
);
