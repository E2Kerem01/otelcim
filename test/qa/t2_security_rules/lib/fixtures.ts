// Payload builders that reproduce, key for key, what the Flutter models
// write (see fixtures/client_payload_keys.json, which the Dart contract test
// pins to the real models), plus the standard cast of test users.
import { readFileSync } from 'node:fs';
import { adminSdk, SERVER_TIMESTAMP } from './emulator.ts';
import type { Data } from './emulator.ts';

export const PAYLOAD_KEYS = JSON.parse(
  readFileSync(new URL('../fixtures/client_payload_keys.json', import.meta.url), 'utf8'),
) as Record<string, string[]>;

export const ADMIN = 'admin_uid';
export const ALICE = 'alice_employer';
export const BOB = 'bob_seeker';
export const EVE = 'eve_attacker';

const NOW = new Date('2026-09-23T10:00:00Z');

/** UserProfile.toFirestore() */
export function profilePayload(uid: string, overrides: Data = {}): Data {
  return {
    email: `${uid}@example.com`,
    displayName: uid,
    phoneNumber: '+905551112233',
    bio: null,
    photoUrl: null,
    hotelName: null,
    position: null,
    userType: 'jobseeker',
    isVerified: false,
    verificationStatus: null,
    verifiedAt: null,
    notificationPreferences: { messages: true, listingAlerts: true, seasonalReminders: false, urgentListings: true, marketing: false },
    quietHoursStart: null,
    quietHoursEnd: null,
    availableImmediately: false,
    preferredExperienceLevel: null,
    preferredEducationLevel: null,
    preferredRegion: null,
    introVideoUrl: null,
    referralCode: `REF${uid.slice(0, 5).toUpperCase()}`,
    referredBy: null,
    createdAt: NOW,
    updatedAt: NOW,
    searchKeywords: [],
    ...overrides,
  };
}

/** Listing.toMap() */
export function listingPayload(posterId: string, overrides: Data = {}): Data {
  return {
    posterId,
    posterName: 'Otel Deniz',
    posterVerified: false,
    isUrgent: false,
    title: 'Ön Büro Resepsiyonisti',
    description: 'Sezonluk resepsiyon görevlisi aranıyor.',
    season: null,
    contractStartDate: null,
    contractEndDate: null,
    category: 'on_buro',
    location: 'Antalya',
    salary: '35.000 TL',
    city: 'Antalya',
    region: 'Antalya',
    lat: 36.8969,
    lng: 30.7133,
    minSalaryTl: 35000,
    maxSalaryTl: 40000,
    employmentType: 'seasonal',
    experienceLevel: null,
    educationLevel: null,
    images: [],
    housingRoomType: null,
    housingHasAc: null,
    housingHasWifi: null,
    housingMealsIncluded: null,
    housingImages: [],
    staffShuttleRoute: null,
    status: 'active',
    createdAt: SERVER_TIMESTAMP,
    updatedAt: SERVER_TIMESTAMP,
    searchKeywords: [],
    isBoosted: false,
    boostExpiresAt: null,
    boostType: null,
    boostPurchaseId: null,
    viewCount: 0,
    messageCount: 0,
    ...overrides,
  };
}

/** Conversation.toMap() for a brand-new conversation. */
export function conversationPayload(listingId: string, posterId: string, seekerId: string, overrides: Data = {}): Data {
  return {
    listingId,
    listingTitle: 'Ön Büro Resepsiyonisti',
    posterId,
    seekerId,
    participantIds: [posterId, seekerId],
    lastMessage: '',
    lastSenderId: '',
    updatedAt: SERVER_TIMESTAMP,
    createdAt: SERVER_TIMESTAMP,
    hired: false,
    hiredAt: null,
    ...overrides,
  };
}

/** Message.toMap() */
export function messagePayload(senderId: string, text: string, overrides: Data = {}): Data {
  return { senderId, text, sentAt: SERVER_TIMESTAMP, ...overrides };
}

/** Report.toMap() */
export function reportPayload(reporterId: string, targetId: string, overrides: Data = {}): Data {
  return {
    reporterId,
    targetId,
    targetType: 'listing',
    reason: 'scam',
    description: null,
    createdAt: SERVER_TIMESTAMP,
    ...overrides,
  };
}

/** Rating.toMap() — note the model's default moderationStatus is `approved`. */
export function ratingPayload(raterId: string, ratedUserId: string, conversationId: string, overrides: Data = {}): Data {
  return {
    conversationId,
    raterId,
    ratedUserId,
    stars: 5,
    reviewText: null,
    createdAt: SERVER_TIMESTAMP,
    moderationStatus: 'approved',
    ...overrides,
  };
}

/** Certificate.toMap() */
export function certificatePayload(userId: string, overrides: Data = {}): Data {
  return {
    userId,
    userName: userId,
    userEmail: `${userId}@example.com`,
    type: 'hijyen',
    title: 'Hijyen Belgesi',
    fileUrl: `https://storage.example/certificates/${userId}/c1.pdf`,
    status: 'pending',
    createdAt: NOW,
    reviewedBy: null,
    reviewedAt: null,
    rejectionReason: null,
    ...overrides,
  };
}

/** Shared VerificationRequest.toFirestore() */
export function verificationPayload(uid: string, overrides: Data = {}): Data {
  return {
    employerId: uid,
    submittedAt: NOW,
    userId: uid,
    userEmail: `${uid}@example.com`,
    hotelName: 'Otel Deniz',
    hotelAddress: 'Lara, Antalya',
    documentUrls: [],
    status: 'pending',
    requestedAt: NOW,
    reviewedAt: null,
    reviewedBy: null,
    rejectionReason: null,
    ...overrides,
  };
}

/** InterviewSlot.toMap() */
export function interviewSlotPayload(proposedBy: string, overrides: Data = {}): Data {
  return {
    proposedBy,
    slots: [new Date('2026-10-01T09:00:00Z'), new Date('2026-10-02T09:00:00Z')],
    selectedSlot: null,
    status: 'pending',
    createdAt: NOW,
    ...overrides,
  };
}

/**
 * Seeds the standard cast: an admin (isAdmin written by the Admin SDK),
 * Alice (employer), Bob (job seeker), Eve (attacker).
 */
export async function seedUsers(): Promise<void> {
  await adminSdk.set(`user_profiles/${ADMIN}`, profilePayload(ADMIN, { isAdmin: true, adminRole: 'superAdmin' }));
  await adminSdk.set(
    `user_profiles/${ALICE}`,
    profilePayload(ALICE, { userType: 'employer', hotelName: 'Otel Deniz', freeBoostCredits: 0, referralCount: 0 }),
  );
  await adminSdk.set(`user_profiles/${BOB}`, profilePayload(BOB, { fcmToken: 'bob-device-token' }));
  await adminSdk.set(`user_profiles/${EVE}`, profilePayload(EVE));
}

/** An active listing owned by Alice, with its private contact subdoc. */
export async function seedListing(id = 'listing1', overrides: Data = {}): Promise<void> {
  await adminSdk.set(`listings/${id}`, listingPayload(ALICE, { createdAt: NOW, updatedAt: NOW, ...overrides }));
  await adminSdk.set(`listings/${id}/private/contact`, { value: '+90 555 000 11 22' });
}

/** A conversation between Alice (poster) and Bob (seeker) about listing1. */
export const CONVO = `listing1_${BOB}`;
export async function seedConversation(overrides: Data = {}): Promise<void> {
  await adminSdk.set(
    `conversations/${CONVO}`,
    conversationPayload('listing1', ALICE, BOB, { createdAt: NOW, updatedAt: NOW, ...overrides }),
  );
}
