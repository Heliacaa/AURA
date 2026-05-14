const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { FieldValue, getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
const db = getFirestore();

function requireUid(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Giriş yapılmamış.");
  }
  return request.auth.uid;
}

function normalizeEmail(value) {
  return String(value || "").trim().toLowerCase();
}

function friendshipIdFor(uidA, uidB) {
  return [uidA, uidB].sort().join("_");
}

function userSnapshot(uid, data) {
  return {
    uid,
    displayName: data.displayName || "",
    email: data.email || "",
    avatarUrl: data.avatarUrl || "",
  };
}

async function getUserDocOrThrow(uid) {
  const doc = await db.collection("users").doc(uid).get();
  if (!doc.exists) {
    throw new HttpsError("not-found", "Kullanıcı bulunamadı.");
  }
  return doc;
}

function relationshipStatus(uid, targetUid, relationship) {
  if (uid === targetUid) return "self";
  if (!relationship || !relationship.exists) return "none";

  const data = relationship.data() || {};
  if (data.status === "accepted") return "accepted";
  if (data.status === "pending" && data.requesterUid === uid) {
    return "outgoingPending";
  }
  if (data.status === "pending" && data.recipientUid === uid) {
    return "incomingPending";
  }
  return "none";
}

function publicProfilePayload({
  uid,
  viewerUid,
  userData,
  relationship,
  includeEmail = false,
}) {
  const status = relationshipStatus(viewerUid, uid, relationship);
  const isFriendVisible = status === "accepted" || status === "self";
  const payload = {
    uid,
    displayName: userData.displayName || "",
    avatarUrl: userData.avatarUrl || "",
    currentLevel: userData.currentLevel || 1,
    currentClass: userData.currentClass || "Novice",
    xp: userData.xp || 0,
    streakDays: userData.streakDays || 0,
    weeklyXp: userData.weeklyXp || 0,
    weeklyXpWeek: userData.weeklyXpWeek || "",
    relationshipStatus: status,
    friendshipId: relationship && relationship.exists ? relationship.id : null,
  };

  if (includeEmail || status === "self") {
    payload.email = userData.email || "";
  }

  if (isFriendVisible) {
    if (userData.age !== undefined) payload.age = userData.age;
    payload.dailyGoals = userData.dailyGoals || {
      steps: 10000,
      calories: 2000,
      waterGlasses: 8,
    };
    payload.socialEnergyLevel = userData.socialEnergyLevel || "Orta";
  }

  return payload;
}

async function buildPublicProfile(uid, viewerUid, options = {}) {
  const userDoc = await getUserDocOrThrow(uid);
  const relationshipId = friendshipIdFor(uid, viewerUid);
  const relationship = uid === viewerUid
    ? null
    : await db.collection("friendships").doc(relationshipId).get();

  return publicProfilePayload({
    uid,
    viewerUid,
    userData: userDoc.data() || {},
    relationship,
    includeEmail: options.includeEmail || false,
  });
}

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

exports.searchUserByEmail = onCall(async (request) => {
  const uid = requireUid(request);
  const rawEmail = String((request.data && request.data.email) || "").trim();
  const email = normalizeEmail(rawEmail);
  if (!email) {
    throw new HttpsError("invalid-argument", "E-posta gerekli.");
  }

  let snap = await db
    .collection("users")
    .where("emailLower", "==", email)
    .limit(1)
    .get();

  if (snap.empty) {
    snap = await db
      .collection("users")
      .where("email", "==", rawEmail)
      .limit(1)
      .get();
  }

  if (snap.empty) return null;

  const userDoc = snap.docs[0];
  return buildPublicProfile(userDoc.id, uid, { includeEmail: true });
});

exports.getPublicProfile = onCall(async (request) => {
  const viewerUid = requireUid(request);
  const uid = String((request.data && request.data.uid) || "").trim();
  if (!uid) {
    throw new HttpsError("invalid-argument", "Kullanıcı kimliği gerekli.");
  }

  return buildPublicProfile(uid, viewerUid);
});

exports.sendFriendRequest = onCall(async (request) => {
  const fromUid = requireUid(request);
  const toUid = String((request.data && request.data.toUid) || "").trim();
  if (!toUid) {
    throw new HttpsError("invalid-argument", "Hedef kullanıcı gerekli.");
  }
  if (fromUid === toUid) {
    throw new HttpsError("failed-precondition", "Kendinizi ekleyemezsiniz.");
  }

  const relationshipId = friendshipIdFor(fromUid, toUid);
  const relationshipRef = db.collection("friendships").doc(relationshipId);
  const fromRef = db.collection("users").doc(fromUid);
  const toRef = db.collection("users").doc(toUid);

  await db.runTransaction(async (transaction) => {
    const relationshipDoc = await transaction.get(relationshipRef);
    if (relationshipDoc.exists) {
      const data = relationshipDoc.data() || {};
      if (data.status === "accepted") {
        throw new HttpsError("already-exists", "Zaten arkadaşsınız.");
      }
      if (data.status === "pending") {
        throw new HttpsError(
          "already-exists",
          "Bu kullanıcıyla bekleyen bir istek var."
        );
      }
    }

    const fromDoc = await transaction.get(fromRef);
    const toDoc = await transaction.get(toRef);
    if (!fromDoc.exists || !toDoc.exists) {
      throw new HttpsError("not-found", "Kullanıcı bulunamadı.");
    }

    const fromData = fromDoc.data() || {};
    const toData = toDoc.data() || {};
    transaction.set(relationshipRef, {
      participantUids: [fromUid, toUid],
      requesterUid: fromUid,
      recipientUid: toUid,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
      requester: userSnapshot(fromUid, fromData),
      recipient: userSnapshot(toUid, toData),
    });
  });

  return { success: true };
});

exports.acceptFriendRequest = onCall(async (request) => {
  const uid = requireUid(request);
  const otherUid = String((request.data && request.data.otherUid) || "").trim();
  if (!otherUid) {
    throw new HttpsError("invalid-argument", "Kullanıcı kimliği gerekli.");
  }

  const relationshipRef = db
    .collection("friendships")
    .doc(friendshipIdFor(uid, otherUid));

  await db.runTransaction(async (transaction) => {
    const relationshipDoc = await transaction.get(relationshipRef);
    if (!relationshipDoc.exists) {
      throw new HttpsError("not-found", "Arkadaşlık isteği bulunamadı.");
    }

    const data = relationshipDoc.data() || {};
    if (data.status !== "pending" || data.recipientUid !== uid) {
      throw new HttpsError(
        "permission-denied",
        "Bu isteği kabul etme yetkiniz yok."
      );
    }

    transaction.update(relationshipRef, {
      status: "accepted",
      updatedAt: FieldValue.serverTimestamp(),
      acceptedAt: FieldValue.serverTimestamp(),
    });
  });

  return { success: true };
});

exports.declineFriendRequest = onCall(async (request) => {
  const uid = requireUid(request);
  const otherUid = String((request.data && request.data.otherUid) || "").trim();
  if (!otherUid) {
    throw new HttpsError("invalid-argument", "Kullanıcı kimliği gerekli.");
  }

  const relationshipRef = db
    .collection("friendships")
    .doc(friendshipIdFor(uid, otherUid));

  await db.runTransaction(async (transaction) => {
    const relationshipDoc = await transaction.get(relationshipRef);
    if (!relationshipDoc.exists) return;

    const data = relationshipDoc.data() || {};
    const isParticipant =
      Array.isArray(data.participantUids) && data.participantUids.includes(uid);
    if (!isParticipant || data.status !== "pending") {
      throw new HttpsError(
        "permission-denied",
        "Bu isteği güncelleme yetkiniz yok."
      );
    }

    transaction.delete(relationshipRef);
  });

  return { success: true };
});

exports.removeFriend = onCall(async (request) => {
  const uid = requireUid(request);
  const otherUid = String((request.data && request.data.otherUid) || "").trim();
  if (!otherUid) {
    throw new HttpsError("invalid-argument", "Kullanıcı kimliği gerekli.");
  }

  const relationshipRef = db
    .collection("friendships")
    .doc(friendshipIdFor(uid, otherUid));

  await db.runTransaction(async (transaction) => {
    const relationshipDoc = await transaction.get(relationshipRef);
    if (!relationshipDoc.exists) return;

    const data = relationshipDoc.data() || {};
    const isParticipant =
      Array.isArray(data.participantUids) && data.participantUids.includes(uid);
    if (!isParticipant || data.status !== "accepted") {
      throw new HttpsError(
        "permission-denied",
        "Bu arkadaşı kaldırma yetkiniz yok."
      );
    }

    transaction.delete(relationshipRef);
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
      const waterGoal = goals.waterGlasses || 8;
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
