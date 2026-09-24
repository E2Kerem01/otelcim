// Resets the local Firebase emulators (Auth :9099, Firestore :8080) and seeds
// the fixed E2E dataset every Maestro flow relies on. Zero dependencies.
//
//   node .maestro/seed/seed.mjs
//
// Never points at production: both hosts are hardcoded to 127.0.0.1.
const PROJECT = 'otelcim-7f0ba';
const AUTH = 'http://127.0.0.1:9099';
const FS = 'http://127.0.0.1:8080';
const DOCS = `${FS}/v1/projects/${PROJECT}/databases/(default)/documents`;
export const PASSWORD = 'Test1234!';

const DAY = 24 * 60 * 60 * 1000;
const now = Date.now();
const ts = (ms) => ({ __ts: new Date(ms).toISOString() });

function toValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (v && v.__ts) return { timestampValue: v.__ts };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, toValue(x)])) } };
}

async function req(method, url, body) {
  const res = await fetch(url, {
    method,
    headers: { 'Content-Type': 'application/json', Authorization: 'Bearer owner' },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw new Error(`${method} ${url} -> ${res.status} ${await res.text()}`);
  return res.status === 204 ? null : res.json().catch(() => null);
}

const setDoc = (path, data) =>
  req('PATCH', `${DOCS}/${path}`, { fields: toValue(data).mapValue.fields });

async function createUser(email, displayName) {
  const r = await req('POST', `${AUTH}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=e2e`, {
    email, password: PASSWORD, displayName, returnSecureToken: true,
  });
  return r.localId;
}

function profile(uid, email, displayName, userType, extra = {}) {
  return {
    email, displayName, userType,
    phoneNumber: null, bio: null, photoUrl: null,
    hotelName: null, position: null,
    isVerified: false, verificationStatus: null, verifiedAt: null,
    notificationPreferences: { messages: true, urgentListings: true, reminders: true },
    availableImmediately: false, preferredRegion: null,
    referralCode: uid.slice(0, 8).toUpperCase(), referredBy: null,
    createdAt: ts(now - 30 * DAY), updatedAt: ts(now - 30 * DAY),
    ...extra,
  };
}

// region is a tourism-region id (antalya, bodrum, cesme, kapadokya ...), as
// the create/edit forms write it - not a province name.
function listing(posterId, posterName, posterVerified, o) {
  return {
    posterId, posterName, posterVerified,
    isUrgent: false, season: 'yaz_2026',
    contractStartDate: ts(now + 20 * DAY), contractEndDate: ts(now + 150 * DAY),
    location: o.city, lat: null, lng: null,
    minSalaryTl: null, maxSalaryTl: null,
    employmentType: 'seasonal', experienceLevel: null, educationLevel: null,
    images: [], housingRoomType: null, housingHasAc: false, housingHasWifi: false,
    housingMealsIncluded: null, housingImages: [], staffShuttleRoute: null,
    status: 'active',
    isBoosted: false, boostExpiresAt: null, boostType: null, boostPurchaseId: null,
    viewCount: 0, messageCount: 0,
    createdAt: ts(now - (o.ageDays ?? 1) * DAY), updatedAt: ts(now - (o.ageDays ?? 1) * DAY),
    ...o,
  };
}

async function main() {
  await req('DELETE', `${FS}/emulator/v1/projects/${PROJECT}/databases/(default)/documents`);
  await req('DELETE', `${AUTH}/emulator/v1/projects/${PROJECT}/accounts`);

  const u = {};
  const users = [
    ['seeker', 'seeker@e2e.test', 'Ayşe Aday', 'jobseeker', { preferredRegion: 'antalya', availableImmediately: true, bio: 'Resepsiyon deneyimi 2 yıl' }],
    ['employer', 'employer@e2e.test', 'Mehmet İşveren', 'employer', { hotelName: 'Deniz Otel', position: 'İK Müdürü', isVerified: true, verificationStatus: 'approved', verifiedAt: ts(now - 10 * DAY) }],
    ['employer2', 'employer2@e2e.test', 'Zeynep Otelci', 'employer', { hotelName: 'Kaya Butik Otel' }],
    ['admin', 'admin@e2e.test', 'Admin Yönetici', 'employer', { isAdmin: true, adminRole: 'super_admin' }],
    ['banned', 'banned@e2e.test', 'Banlı Kullanıcı', 'jobseeker', { isBanned: true, warnings: [{ reason: 'spam' }] }],
    ['suspended', 'suspended@e2e.test', 'Askıda Kullanıcı', 'jobseeker', { isSuspended: true, suspensionEnd: ts(now + 365 * DAY) }],
    // Own the pending admin-review items below, so seeker/employer2 screens
    // keep their empty states.
    ['employer3', 'employer3@e2e.test', 'Can Başvuran', 'employer', { hotelName: 'Yeni Otel', verificationStatus: 'pending' }],
    ['seeker2', 'seeker2@e2e.test', 'Ali Aday', 'jobseeker', { preferredRegion: 'bodrum' }],
  ];
  for (const [key, email, name, type, extra] of users) {
    u[key] = await createUser(email, name);
    await setDoc(`user_profiles/${u[key]}`, profile(u[key], email, name, type, extra));
  }

  const E = [u.employer, 'Deniz Otel', true];
  const E2 = [u.employer2, 'Kaya Butik Otel', false];
  const listings = {
    L1: listing(...E, { title: 'Resepsiyonist Aranıyor', description: 'Lara bölgesinde 5 yıldızlı otel için İngilizce bilen resepsiyonist.', category: 'resepsiyon', city: 'Antalya', region: 'antalya', salary: '35.000 TL', minSalaryTl: 35000, maxSalaryTl: 40000, lat: 36.85, lng: 30.85, housingRoomType: 'shared', housingHasAc: true, housingHasWifi: true, housingMealsIncluded: 3, ageDays: 1 }),
    L2: listing(...E, { title: 'Garson (Sezonluk)', description: 'Alakart restoran için deneyimli garson.', category: 'servisGarson', city: 'Antalya', region: 'antalya', salary: '28.000 TL', minSalaryTl: 28000, maxSalaryTl: 30000, ageDays: 2 }),
    L3: listing(...E, { title: 'Acil Aşçı Yardımcısı', description: 'Hemen başlayacak aşçı yardımcısı.', category: 'mutfakAsci', city: 'Antalya', region: 'antalya', salary: '30.000 TL', minSalaryTl: 30000, maxSalaryTl: 32000, isUrgent: true, ageDays: 0 }),
    L4: listing(...E, { title: 'Barmen - Boost', description: 'Havuz bar için barmen.', category: 'barBarmen', city: 'Antalya', region: 'antalya', salary: '32.000 TL', minSalaryTl: 32000, maxSalaryTl: 36000, isBoosted: true, boostType: 'boost_7_days', boostExpiresAt: ts(now + 5 * DAY), ageDays: 3 }),
    L5: listing(...E, { title: 'Kapanmış İlan Housekeeping', description: 'Bu ilan kapandı.', category: 'katHizmetleri', city: 'Antalya', region: 'antalya', salary: '25.000 TL', status: 'closed', ageDays: 20 }),
    L6: listing(...E2, { title: 'Animatör', description: 'Bodrum kulüp otel için animatör.', category: 'animasyon', city: 'Bodrum', region: 'bodrum', salary: '27.000 TL', minSalaryTl: 27000, maxSalaryTl: 29000, ageDays: 4 }),
    L7: listing(...E2, { title: 'Spa Terapisti', description: 'Çeşme butik otel spa.', category: 'spaWellness', city: 'Çeşme', region: 'cesme', salary: '33.000 TL', minSalaryTl: 33000, maxSalaryTl: 35000, ageDays: 5 }),
    L8: listing(...E2, { title: 'Güvenlik Görevlisi', description: 'Gece vardiyası güvenlik.', category: 'guvenlik', city: 'Ürgüp', region: 'kapadokya', salary: '26.000 TL', minSalaryTl: 26000, maxSalaryTl: 26000, employmentType: 'fullTime', ageDays: 6 }),
  };
  // `node seed.mjs many` (a flow opts in with a `# seed: many` line): 30 extra
  // active listings P01..P30 so the feed needs more than one page.
  if (process.argv[2] === 'many') {
    const cats = ['resepsiyon', 'servisGarson', 'mutfakAsci', 'katHizmetleri', 'barBarmen', 'animasyon'];
    for (let i = 1; i <= 30; i++) {
      const n = String(i).padStart(2, '0');
      listings[`P${n}`] = listing(...E2, {
        title: `Sayfa İlanı ${n}`, description: `Sayfalama test ilanı ${n}.`,
        category: cats[i % cats.length], city: 'Alanya', region: 'antalya',
        salary: `${20000 + i * 100} TL`, minSalaryTl: 20000 + i * 100, maxSalaryTl: 20000 + i * 100,
        ageDays: 7 + i,
      });
    }
  }
  for (const [id, data] of Object.entries(listings)) {
    await setDoc(`listings/${id}`, data);
    await setDoc(`listings/${id}/private/contact`, { contactInfo: `ik+${id}@e2e.test - 0242 555 00 00` });
  }

  const convId = `L1_${u.seeker}`;
  await setDoc(`conversations/${convId}`, {
    listingId: 'L1', listingTitle: 'Resepsiyonist Aranıyor',
    posterId: u.employer, seekerId: u.seeker, participantIds: [u.employer, u.seeker],
    lastMessage: 'Yarın görüşmeye gelebilir misiniz?', lastSenderId: u.employer,
    createdAt: ts(now - 2 * DAY), updatedAt: ts(now - DAY), hired: false, hiredAt: null,
  });
  await setDoc(`conversations/${convId}/messages/m1`, { senderId: u.seeker, text: 'Merhaba, ilan hâlâ aktif mi?', sentAt: ts(now - 2 * DAY) });
  await setDoc(`conversations/${convId}/messages/m2`, { senderId: u.employer, text: 'Yarın görüşmeye gelebilir misiniz?', sentAt: ts(now - DAY) });

  await setDoc(`user_profiles/${u.seeker}/favorites/L2`, { listingId: 'L2', addedAt: ts(now - DAY) });

  await setDoc('reports/R1', {
    reporterId: u.seeker, targetType: 'listing', targetId: 'L8',
    reason: 'spam', description: 'Şüpheli ilan', status: 'pending', createdAt: ts(now - DAY),
  });

  // L4's boost as the purchase Cloud Function writes it (durationType is the
  // server's 'daysN' form).
  await setDoc('boosts/B1', {
    listingId: 'L4', userId: u.employer, durationType: 'days14', durationDays: 14,
    price: 249.99, purchasedAt: ts(now - 9 * DAY), expiresAt: ts(now + 5 * DAY),
    platform: 'google_play', transactionId: 'GPA.E2E-0001', status: 'active',
  });

  // Pending items for the admin review screens. fileUrl/documentUrls point
  // nowhere real on purpose - never fetch them.
  await setDoc('verification_requests/V1', {
    employerId: u.employer3, userId: u.employer3, hotelName: 'Yeni Otel',
    documentUrls: ['https://example.invalid/e2e/vergi-levhasi.pdf'], status: 'pending',
    submittedAt: ts(now - DAY), requestedAt: ts(now - DAY),
    reviewedBy: null, reviewedAt: null, rejectionReason: null,
  });
  await setDoc('certificates/C1', {
    userId: u.seeker2, userName: 'Ali Aday', userEmail: 'seeker2@e2e.test',
    type: 'hijyen', title: 'Hijyen Eğitimi Sertifikası',
    fileUrl: 'https://example.invalid/e2e/hijyen.pdf', status: 'pending',
    createdAt: ts(now - DAY), reviewedBy: null, reviewedAt: null, rejectionReason: null,
  });
  // Inactive so it never shows in the home feed; admin banners screen lists it.
  await setDoc('banner_ads/A1', {
    title: 'E2E Test Reklamı', advertiserName: 'E2E Reklamcı',
    imageUrl: 'https://example.invalid/e2e/banner.png', targetUrl: 'https://example.invalid',
    order: 1, isActive: false, startDate: null, endDate: null, createdAt: ts(now - DAY),
  });

  console.log(JSON.stringify({ ok: true, uids: u, listings: Object.keys(listings), conversation: convId }));
}

main().catch((e) => { console.error(e.message); process.exit(1); });
