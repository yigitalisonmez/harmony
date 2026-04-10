import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// ── Notification messages ─────────────────────────────────────────────────────

const memoryMessages = [
  "a new memory is waiting for you ✨",
  "they captured something beautiful 💫",
  "a little moment, just for you two 🌸",
  "someone's been thinking of you 📸",
  "a new memory just landed 💕",
  "saved with love, just for you 🎞️",
  "they wanted you to remember this 🤍",
];

const reactionMessages = [
  "they left a little something 🥰",
  "your memory got a reaction ❤️",
  "a little love, just for you ✨",
  "they felt something about this memory 💌",
  "someone can't stop thinking about this one 💫",
];

function pick<T>(arr: T[]): T {
  return arr[Math.floor(Math.random() * arr.length)];
}

async function sendToUser(
  uid: string,
  notification: { title: string; body: string },
  data: Record<string, string>
): Promise<void> {
  const userSnap = await db.collection("users").doc(uid).get();
  const token = userSnap.data()?.fcmToken as string | undefined;
  if (!token) return;

  try {
    await messaging.send({
      token,
      notification,
      data,
      apns: {
        payload: { aps: { sound: "default", badge: 1 } },
      },
      android: {
        notification: {
          sound: "default",
          channelId: "harmony_default",
          color: "#FF6B8A",
        },
      },
    });
  } catch (err) {
    console.error(`FCM send failed for uid=${uid}:`, err);
  }
}

// ── Trigger: new memory added ─────────────────────────────────────────────────

export const onMemoryCreated = onDocumentCreated(
  "couples/{coupleId}/memories/{memoryId}",
  async (event) => {
    const { coupleId, memoryId } = event.params;
    const data = event.data?.data();
    if (!data) return;

    const creatorUid = data["creatorUid"] as string | undefined;

    // Get couple members
    const coupleSnap = await db.collection("couples").doc(coupleId).get();
    const members: string[] = coupleSnap.data()?.members ?? [];

    // Notify everyone except the creator
    const partners = members.filter((uid) => uid !== creatorUid);

    for (const uid of partners) {
      await sendToUser(
        uid,
        { title: "harmony", body: pick(memoryMessages) },
        { type: "new_memory", memoryId, coupleId }
      );
    }
  }
);

// ── Trigger: partner left a reaction ─────────────────────────────────────────

export const onReactionAdded = onDocumentUpdated(
  "couples/{coupleId}/memories/{memoryId}",
  async (event) => {
    const { coupleId, memoryId } = event.params;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Only trigger when a reaction is newly added (not removed or unchanged)
    const hadReaction = Boolean(before["partnerReaction"]);
    const hasReaction = Boolean(after["partnerReaction"]);
    if (hadReaction || !hasReaction) return;

    // Notify the memory creator
    const creatorUid = after["creatorUid"] as string | undefined;
    if (!creatorUid) return;

    await sendToUser(
      creatorUid,
      { title: "harmony", body: pick(reactionMessages) },
      { type: "reaction", memoryId, coupleId }
    );
  }
);
