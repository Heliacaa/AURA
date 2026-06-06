"use strict";

const fs = require("node:fs");
const {
  after,
  before,
  beforeEach,
  test,
} = require("node:test");
const {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} = require("@firebase/rules-unit-testing");
const {
  arrayRemove,
  arrayUnion,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} = require("firebase/firestore");

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "aura-d27e0",
    firestore: {
      rules: fs.readFileSync("firestore.rules", "utf8"),
    },
  });
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

after(async () => {
  await testEnv.cleanup();
});

async function seedUser(uid, overrides = {}) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "users", uid), {
      displayName: `User ${uid}`,
      avatarUrl: "",
      shareMilestones: true,
      streakDays: 3,
      currentLevel: 2,
      currentClass: "Novice",
      ...overrides,
    });
  });
}

async function seedFriendship(uidA, uidB) {
  const id = [uidA, uidB].sort().join("_");
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "friendships", id), {
      participantUids: [uidA, uidB],
      requesterUid: uidA,
      recipientUid: uidB,
      status: "accepted",
    });
  });
  return id;
}

async function seedActivity(id, actorUid, visibility = "friends") {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "social_activities", id), {
      type: "streak_milestone",
      actorUid,
      actorDisplayName: `User ${actorUid}`,
      actorAvatarUrl: "",
      title: "Milestone",
      description: "",
      metadata: { days: 3 },
      visibility,
      createdAt: serverTimestamp(),
      isSpecialAchievement: true,
    });
  });
}

function streakActivity(uid, overrides = {}) {
  return {
    type: "streak_milestone",
    actorUid: uid,
    actorDisplayName: `User ${uid}`,
    actorAvatarUrl: "",
    title: "3 Günlük Seri!",
    description: `User ${uid}, 3 günlük seriye ulaştı.`,
    metadata: { days: 3 },
    visibility: "friends",
    createdAt: serverTimestamp(),
    isSpecialAchievement: true,
    ...overrides,
  };
}

test("users can create only their own valid milestone activity", async () => {
  await seedUser("u1");
  const user = testEnv.authenticatedContext("u1").firestore();

  await assertSucceeds(
    setDoc(
      doc(user, "social_activities", "streak_u1_3"),
      streakActivity("u1")
    )
  );
  await assertFails(
    setDoc(
      doc(user, "social_activities", "streak_u2_3"),
      streakActivity("u2")
    )
  );
  await assertFails(
    setDoc(
      doc(user, "social_activities", "global"),
      streakActivity("u1", { visibility: "global" })
    )
  );
  await assertFails(
    setDoc(
      doc(user, "social_activities", "streak_u1_999"),
      streakActivity("u1")
    )
  );
});

test("legacy users without avatarUrl can create milestone activity", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "users", "u1"), {
      displayName: "User u1",
      shareMilestones: true,
      streakDays: 3,
      currentLevel: 2,
      currentClass: "Novice",
    });
  });
  const user = testEnv.authenticatedContext("u1").firestore();

  await assertSucceeds(
    setDoc(
      doc(user, "social_activities", "streak_u1_3"),
      streakActivity("u1")
    )
  );
});

test("legacy users without currentClass can create level activity", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "users", "u1"), {
      displayName: "User u1",
      shareMilestones: true,
      currentLevel: 2,
    });
  });
  const user = testEnv.authenticatedContext("u1").firestore();

  await assertSucceeds(
    setDoc(doc(user, "social_activities", "level_u1_2"), {
      type: "level_up",
      actorUid: "u1",
      actorDisplayName: "User u1",
      actorAvatarUrl: "",
      title: "Seviye 2!",
      description: "User u1, 2. seviyeye yükseldi.",
      metadata: { level: 2, className: "Novice" },
      visibility: "friends",
      createdAt: serverTimestamp(),
      isSpecialAchievement: true,
    })
  );
});

test("shareMilestones false blocks new social activities", async () => {
  await seedUser("u1", { shareMilestones: false });
  const user = testEnv.authenticatedContext("u1").firestore();

  await assertFails(
    setDoc(
      doc(user, "social_activities", "streak_u1_3"),
      streakActivity("u1")
    )
  );
});

test("friend access follows the current friendship relationship", async () => {
  await seedUser("u1");
  await seedActivity("friends-only", "u1");
  const friendshipId = await seedFriendship("u1", "u2");
  const friend = testEnv.authenticatedContext("u2").firestore();
  const stranger = testEnv.authenticatedContext("u3").firestore();

  await assertSucceeds(getDoc(doc(friend, "social_activities", "friends-only")));
  await assertFails(getDoc(doc(stranger, "social_activities", "friends-only")));

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await deleteDoc(doc(context.firestore(), "friendships", friendshipId));
  });
  await assertFails(getDoc(doc(friend, "social_activities", "friends-only")));
});

test("friend feed queries are authorized by actor relationship", async () => {
  await seedUser("u1");
  await seedActivity("activity-u1", "u1");
  await seedFriendship("u1", "u2");
  const friend = testEnv.authenticatedContext("u2").firestore();
  const stranger = testEnv.authenticatedContext("u3").firestore();
  const friendFeed = query(
    collection(friend, "social_activities"),
    where("actorUid", "==", "u1")
  );
  const strangerFeed = query(
    collection(stranger, "social_activities"),
    where("actorUid", "==", "u1")
  );

  await assertSucceeds(getDocs(friendFeed));
  await assertFails(getDocs(strangerFeed));
});

test("friendship participant queries are limited to the signed-in user", async () => {
  await seedFriendship("u1", "u2");
  await seedFriendship("u3", "u4");
  const user = testEnv.authenticatedContext("u1").firestore();
  const ownFriendships = query(
    collection(user, "friendships"),
    where("participantUids", "array-contains", "u1")
  );
  const otherFriendships = query(
    collection(user, "friendships"),
    where("participantUids", "array-contains", "u3")
  );

  await assertSucceeds(getDocs(ownFriendships));
  await assertFails(getDocs(otherFriendships));
});

test("global activities are readable but remain admin-created", async () => {
  await seedActivity("global", "", "global");
  const user = testEnv.authenticatedContext("u3").firestore();
  const globalFeed = query(
    collection(user, "social_activities"),
    where("visibility", "==", "global")
  );

  await assertSucceeds(getDoc(doc(user, "social_activities", "global")));
  await assertSucceeds(getDocs(globalFeed));
  await assertFails(
    setDoc(doc(user, "social_activities", "forged-global"), {
      visibility: "global",
    })
  );
});

test("activity owners can sync profile fields and delete their own activity", async () => {
  await seedUser("u1", { displayName: "New User", avatarUrl: "new-avatar" });
  await seedActivity("activity-u1", "u1");
  const user = testEnv.authenticatedContext("u1").firestore();
  const stranger = testEnv.authenticatedContext("u2").firestore();
  const activity = doc(user, "social_activities", "activity-u1");
  const strangerActivity = doc(stranger, "social_activities", "activity-u1");

  await assertSucceeds(
    updateDoc(activity, {
      actorDisplayName: "New User",
      actorAvatarUrl: "new-avatar",
      description: "New User, 3 günlük seriye ulaştı.",
    })
  );

  await assertFails(updateDoc(activity, { title: "Changed" }));
  await assertFails(updateDoc(activity, { metadata: { days: 7 } }));
  await assertFails(deleteDoc(strangerActivity));
  await assertSucceeds(deleteDoc(activity));
});

test("activity likes live under and belong to the current user", async () => {
  await seedUser("u1");
  await seedActivity("activity-u1", "u1");
  await seedFriendship("u1", "u2");
  const user = testEnv.authenticatedContext("u2").firestore();

  await assertSucceeds(
    setDoc(doc(user, "users/u2/activityLikes/activity-u1"), {
      uid: "u2",
      activityId: "activity-u1",
      createdAt: serverTimestamp(),
    })
  );
  await assertFails(
    setDoc(doc(user, "users/u3/activityLikes/activity-u1"), {
      uid: "u3",
      activityId: "activity-u1",
      createdAt: serverTimestamp(),
    })
  );
});

test("challenge membership changes only the participant list", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "social_challenges", "steps"), {
      title: "Steps",
      description: "",
      type: "steps",
      currentAmount: 0,
      targetAmount: 1000,
      unit: "Adım",
      participants: [],
      createdAt: serverTimestamp(),
      endDate: serverTimestamp(),
    });
  });
  const user = testEnv.authenticatedContext("u1").firestore();
  const challenge = doc(user, "social_challenges", "steps");

  await assertSucceeds(updateDoc(challenge, { participants: arrayUnion("u1") }));
  await assertFails(updateDoc(challenge, { currentAmount: 500 }));

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await updateDoc(
      doc(context.firestore(), "social_challenges", "steps"),
      { participants: ["u1", "u2", "u3"] }
    );
  });
  await assertFails(updateDoc(challenge, { participants: ["u2", "u2"] }));
  await assertSucceeds(
    updateDoc(challenge, { participants: arrayRemove("u1") })
  );
});

test("challenge contribution belongs to the user and only increases to daily log", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "social_challenges", "steps"), {
      title: "Steps",
      type: "steps",
      participants: ["u1"],
    });
    await setDoc(doc(db, "users/u1/dailyLogs/2026-06-04"), {
      stepCount: 500,
      waterGlasses: 2,
    });
  });
  const user = testEnv.authenticatedContext("u1").firestore();
  const contribution = doc(
    user,
    "social_challenges/steps/progressContributions/u1_2026-06-04"
  );

  await assertSucceeds(
    setDoc(contribution, {
      challengeId: "steps",
      userId: "u1",
      logId: "2026-06-04",
      creditedAmount: 400,
      updatedAt: serverTimestamp(),
    })
  );
  await assertSucceeds(
    updateDoc(contribution, {
      creditedAmount: 500,
      updatedAt: serverTimestamp(),
    })
  );
  await assertFails(
    updateDoc(contribution, {
      creditedAmount: 300,
      updatedAt: serverTimestamp(),
    })
  );
  await assertFails(
    updateDoc(contribution, {
      creditedAmount: 600,
      updatedAt: serverTimestamp(),
    })
  );

  const otherUser = testEnv.authenticatedContext("u2").firestore();
  await assertFails(
    setDoc(
      doc(
        otherUser,
        "social_challenges/steps/progressContributions/u1_2026-06-04"
      ),
      {
        challengeId: "steps",
        userId: "u1",
        logId: "2026-06-04",
        creditedAmount: 500,
        updatedAt: serverTimestamp(),
      }
    )
  );

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await updateDoc(doc(db, "social_challenges", "steps"), {
      participants: [],
    });
    await updateDoc(doc(db, "users/u1/dailyLogs/2026-06-04"), {
      stepCount: 600,
    });
  });
  await assertFails(
    updateDoc(contribution, {
      creditedAmount: 600,
      updatedAt: serverTimestamp(),
    })
  );
  await assertFails(deleteDoc(contribution));
});
