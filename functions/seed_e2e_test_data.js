// TEST-ONLY script. Seeds two fake accounts + a conversation into the local
// Firebase Auth/Firestore emulators for live UI testing. Never touches
// production — requires FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST
// to be set, which only exist in this local shell session.
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';

const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'otelcim-7f0ba' });

const auth = admin.auth();
const db = admin.firestore();

const USERS = [
  {
    uid: 'e2e_poster_1',
    email: 'poster@e2e.test',
    password: 'Test1234!',
    profile: {
      email: 'poster@e2e.test',
      displayName: 'E2E Poster Otel',
      userType: 'employer',
      hotelName: 'E2E Poster Otel',
      isAdmin: false,
      isVerified: true,
      notificationPreferences: {
        messages: true,
        listingAlerts: true,
        seasonalReminders: false,
        urgentListings: true,
        marketing: false,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  },
  {
    uid: 'e2e_seeker_1',
    email: 'seeker@e2e.test',
    password: 'Test1234!',
    profile: {
      email: 'seeker@e2e.test',
      displayName: 'E2E Seeker Aday',
      userType: 'jobseeker',
      isAdmin: false,
      isVerified: false,
      notificationPreferences: {
        messages: true,
        listingAlerts: true,
        seasonalReminders: false,
        urgentListings: true,
        marketing: false,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
  },
];

async function main() {
  for (const u of USERS) {
    try {
      await auth.createUser({ uid: u.uid, email: u.email, password: u.password, emailVerified: true });
      console.log(`created auth user ${u.email}`);
    } catch (e) {
      console.log(`auth user ${u.email} already exists or error: ${e.message}`);
    }
    await db.collection('user_profiles').doc(u.uid).set(u.profile, { merge: true });
    console.log(`seeded profile for ${u.email}`);
  }

  await db.collection('listings').doc('e2e_listing_1').set({
    posterId: 'e2e_poster_1',
    posterName: 'E2E Poster Otel',
    posterVerified: true,
    isUrgent: false,
    title: 'E2E Test İlanı - Resepsiyonist',
    description: 'Otomatik test için oluşturulmuş ilan.',
    category: 'resepsiyon',
    location: 'Antalya',
    salary: '25000-30000 TL',
    city: 'Antalya',
    images: [],
    housingImages: [],
    status: 'active',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    isBoosted: false,
    viewCount: 0,
    messageCount: 1,
  }, { merge: true });
  // contactInfo lives in listings/{id}/private/contact, not the public doc
  // (see firestore.rules) - seed it the same way the app writes it, so the
  // signed-in-gated reveal flow is actually exercised by this test data.
  await db.collection('listings').doc('e2e_listing_1').collection('private').doc('contact')
    .set({ value: '5551234567' });
  console.log('seeded listing e2e_listing_1');

  const convRef = db.collection('conversations').doc('e2e_conv_1');
  await convRef.set({
    listingId: 'e2e_listing_1',
    listingTitle: 'E2E Test İlanı - Resepsiyonist',
    posterId: 'e2e_poster_1',
    seekerId: 'e2e_seeker_1',
    participantIds: ['e2e_poster_1', 'e2e_seeker_1'],
    lastMessage: 'Merhaba, pozisyon hala açık mı?',
    lastSenderId: 'e2e_seeker_1',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    hired: false,
  }, { merge: true });
  await convRef.collection('messages').add({
    senderId: 'e2e_seeker_1',
    text: 'Merhaba, pozisyon hala açık mı?',
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  console.log('seeded conversation e2e_conv_1');

  console.log('DONE');
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
