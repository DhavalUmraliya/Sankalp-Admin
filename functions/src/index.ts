import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

admin.initializeApp();

type Target = 'all' | 'inactive';

interface NotificationRequest {
  title: string;
  body: string;
  target: Target;
}

export const sendAdminNotification = functions
  .region('us-central1')
  .https.onCall(async (data: NotificationRequest, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required.',
      );
    }

    const title = (data?.title ?? '').toString().trim();
    const body = (data?.body ?? '').toString().trim();
    const target = (data?.target ?? 'all') as Target;

    if (!title || !body) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Title and body are required.',
      );
    }

    if (target !== 'all' && target !== 'inactive') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Invalid target.',
      );
    }

    const userSnap = await admin
      .firestore()
      .collection('users')
      .doc(context.auth.uid)
      .get();

    if (userSnap.get('role') !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Admin role required.',
      );
    }

    const tokens = await fetchTargetTokens(target);
    if (tokens.length === 0) {
      return { targetCount: 0, successCount: 0, failureCount: 0 };
    }

    const chunks = chunk(tokens, 500);
    let successCount = 0;
    let failureCount = 0;

    for (const batch of chunks) {
      const response = await admin.messaging().sendEachForMulticast({
        tokens: batch,
        notification: { title, body },
      });
      successCount += response.successCount;
      failureCount += response.failureCount;
    }

    return {
      targetCount: tokens.length,
      successCount,
      failureCount,
    };
  });

async function fetchTargetTokens(target: Target): Promise<string[]> {
  const db = admin.firestore();
  const usersRef = db.collection('users');
  const now = admin.firestore.Timestamp.now();
  const sevenDaysAgo = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - 7 * 24 * 60 * 60 * 1000),
  );

  let snapshots: FirebaseFirestore.QuerySnapshot<FirebaseFirestore.DocumentData>[] =
    [];

  if (target === 'all') {
    const snap = await usersRef.where('fcmToken', '!=', null).get();
    snapshots = [snap];
  } else {
    const [inactiveByDate, inactiveMissing] = await Promise.all([
      usersRef.where('lastActiveAt', '<', sevenDaysAgo).get(),
      usersRef.where('lastActiveAt', '==', null).get(),
    ]);
    snapshots = [inactiveByDate, inactiveMissing];
  }

  const tokenSet = new Set<string>();
  for (const snap of snapshots) {
    for (const doc of snap.docs) {
      const data = doc.data();
      const token = data.fcmToken;
      const tokens = data.fcmTokens;

      if (typeof token === 'string' && token) {
        tokenSet.add(token);
      }
      if (Array.isArray(tokens)) {
        for (const t of tokens) {
          if (typeof t === 'string' && t) tokenSet.add(t);
        }
      }
    }
  }

  return Array.from(tokenSet);
}

function chunk<T>(items: T[], size: number): T[][] {
  const result: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    result.push(items.slice(i, i + size));
  }
  return result;
}

