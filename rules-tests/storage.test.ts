import { afterAll, afterEach, beforeAll, describe, it } from 'vitest';
import { assertFails, assertSucceeds, type RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';
import { doc, setDoc } from 'firebase/firestore';
import { makeTestEnv, seed, warmUpRulesRuntime } from './env';

const OWNER = 'owner-uid';
const OTHER = 'other-uid';
const ADMIN = 'admin-uid';

// Content is never decoded by the rules (only contentType/size are checked),
// so any bytes work as a stand-in for a real image/document.
const TINY_FILE = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
const OVERSIZED_FILE = new Uint8Array(10 * 1024 * 1024 + 1);
const IMAGE_META = { contentType: 'image/jpeg' };
const PDF_META = { contentType: 'application/pdf' };

let testEnv: RulesTestEnvironment;

beforeAll(async () => {
  testEnv = await makeTestEnv();
  await warmUpRulesRuntime(testEnv);
});

afterEach(async () => {
  await testEnv.clearStorage();
  await testEnv.clearFirestore();
});

afterAll(async () => {
  await testEnv.cleanup();
});

describe('profile_photos', () => {
  it('lets the owner upload their own photo but not someone else\'s', async () => {
    const ownerStorage = testEnv.authenticatedContext(OWNER).storage();
    const otherStorage = testEnv.authenticatedContext(OTHER).storage();

    await assertSucceeds(
      uploadBytes(ref(ownerStorage, `profile_photos/${OWNER}/profile.jpg`), TINY_FILE, IMAGE_META),
    );
    await assertFails(
      uploadBytes(ref(otherStorage, `profile_photos/${OWNER}/profile.jpg`), TINY_FILE, IMAGE_META),
    );
  });

  it('rejects non-image content types and oversized files', async () => {
    const ownerStorage = testEnv.authenticatedContext(OWNER).storage();

    await assertFails(
      uploadBytes(ref(ownerStorage, `profile_photos/${OWNER}/profile.pdf`), TINY_FILE, PDF_META),
    );
    await assertFails(
      uploadBytes(ref(ownerStorage, `profile_photos/${OWNER}/big.jpg`), OVERSIZED_FILE, IMAGE_META),
    );
  });

  it('is publicly readable', async () => {
    await seed(testEnv, async (context) => {
      await uploadBytes(ref(context.storage(), `profile_photos/${OWNER}/profile.jpg`), TINY_FILE, IMAGE_META);
    });
    const anonStorage = testEnv.unauthenticatedContext().storage();
    await assertSucceeds(getBytes(ref(anonStorage, `profile_photos/${OWNER}/profile.jpg`)));
  });
});

describe('listing_images', () => {
  it('namespaces writes by uploader uid, so one user cannot overwrite another user\'s listing image', async () => {
    const ownerStorage = testEnv.authenticatedContext(OWNER).storage();
    const otherStorage = testEnv.authenticatedContext(OTHER).storage();

    await assertSucceeds(
      uploadBytes(ref(ownerStorage, `listing_images/${OWNER}/L1/photo1.jpg`), TINY_FILE, IMAGE_META),
    );
    await assertFails(
      uploadBytes(ref(otherStorage, `listing_images/${OWNER}/L1/photo1.jpg`), TINY_FILE, IMAGE_META),
    );
  });

  it('does not let a signed-in user delete another user\'s listing image', async () => {
    await seed(testEnv, async (context) => {
      await uploadBytes(ref(context.storage(), `listing_images/${OWNER}/L1/photo1.jpg`), TINY_FILE, IMAGE_META);
    });
    const otherStorage = testEnv.authenticatedContext(OTHER).storage();
    await assertFails(deleteObject(ref(otherStorage, `listing_images/${OWNER}/L1/photo1.jpg`)));
  });
});

describe('verification_documents', () => {
  async function seedVerificationDoc() {
    await seed(testEnv, async (context) => {
      await uploadBytes(ref(context.storage(), `verification_documents/${OWNER}/doc1.pdf`), TINY_FILE, PDF_META);
      await setDoc(doc(context.firestore(), 'user_profiles/' + ADMIN), { isAdmin: true });
    });
  }

  it('is readable by the owner', async () => {
    await seedVerificationDoc();
    const ownerStorage = testEnv.authenticatedContext(OWNER).storage();
    await assertSucceeds(getBytes(ref(ownerStorage, `verification_documents/${OWNER}/doc1.pdf`)));
  });

  it('is readable by an admin', async () => {
    await seedVerificationDoc();
    const adminStorage = testEnv.authenticatedContext(ADMIN).storage();
    await assertSucceeds(getBytes(ref(adminStorage, `verification_documents/${OWNER}/doc1.pdf`)));
  });

  it('is not readable by another signed-in user', async () => {
    await seedVerificationDoc();
    const otherStorage = testEnv.authenticatedContext(OTHER).storage();
    await assertFails(getBytes(ref(otherStorage, `verification_documents/${OWNER}/doc1.pdf`)));
  });
});
