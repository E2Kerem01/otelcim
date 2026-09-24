// storage.rules, driven by the paths / content types StorageService uses.
import { beforeEach, describe, test } from 'node:test';
import { allowed, bug, deleteObject, denied, download, resetFirestore, upload } from '../lib/emulator.ts';
import { ADMIN, ALICE, BOB, EVE, seedUsers } from '../lib/fixtures.ts';

const MB = 1024 * 1024;

beforeEach(async () => {
  // storage.rules' isAdmin() reads user_profiles through firestore.get().
  await resetFirestore();
  await seedUsers();
});

describe('storage: uploads on the paths StorageService writes', () => {
  test('profile photo: owner can upload a JPEG to profile_photos/{uid}/profile.jpg', async () => {
    await allowed(upload(BOB, `profile_photos/${BOB}/profile.jpg`));
    await allowed(download(null, `profile_photos/${BOB}/profile.jpg`));
  });

  test('profile photo: another user or an anonymous caller cannot overwrite it', async () => {
    await denied(upload(EVE, `profile_photos/${BOB}/profile.jpg`));
    await denied(upload(null, `profile_photos/${BOB}/profile.jpg`));
  });

  test('image paths reject non-image content types', async () => {
    await denied(upload(BOB, `profile_photos/${BOB}/profile.jpg`, { contentType: 'text/html' }));
    await denied(upload(ALICE, `listing_images/${ALICE}/l1/0_1.jpg`, { contentType: 'application/pdf' }));
    await denied(upload(ALICE, `housing_images/${ALICE}/l1/0_1.jpg`, { contentType: 'application/octet-stream' }));
  });

  test('image paths: just under 10 MB is allowed, exactly 10 MB is denied', async () => {
    await allowed(upload(ALICE, `listing_images/${ALICE}/l1/0_1.jpg`, { size: 10 * MB - 1 }));
    await denied(upload(ALICE, `listing_images/${ALICE}/l1/1_1.jpg`, { size: 10 * MB }));
  });

  test('listing and housing images: only under the uploader\'s own uid (pre-generated listing id)', async () => {
    await allowed(upload(ALICE, `listing_images/${ALICE}/not_created_yet/0_1.jpg`));
    await allowed(upload(ALICE, `housing_images/${ALICE}/not_created_yet/0_1.jpg`));
    await denied(upload(EVE, `listing_images/${ALICE}/l1/0_1.jpg`));
    await denied(upload(EVE, `housing_images/${ALICE}/l1/0_1.jpg`));
  });

  test('verification documents: owner may upload a PDF; only owner and admin may read', async () => {
    const path = `verification_documents/${ALICE}/1727000000000_tax_id.pdf`;
    await allowed(upload(ALICE, path, { contentType: 'application/pdf' }));
    await allowed(download(ALICE, path));
    await allowed(download(ADMIN, path));
    await denied(download(EVE, path));
    await denied(download(null, path));
    await denied(upload(EVE, `verification_documents/${ALICE}/x.pdf`, { contentType: 'application/pdf' }));
  });

  test('verification documents / certificates: 15 MB limit', async () => {
    await allowed(upload(ALICE, `verification_documents/${ALICE}/big.pdf`, { contentType: 'application/pdf', size: 15 * MB - 1 }));
    await denied(upload(ALICE, `verification_documents/${ALICE}/huge.pdf`, { contentType: 'application/pdf', size: 15 * MB }));
    await denied(upload(BOB, `certificates/${BOB}/c1.pdf`, { contentType: 'application/pdf', size: 15 * MB }));
  });

  test('certificates: owner upload, owner/admin read, strangers denied', async () => {
    await allowed(upload(BOB, `certificates/${BOB}/c1.pdf`, { contentType: 'application/pdf' }));
    await allowed(download(ADMIN, `certificates/${BOB}/c1.pdf`));
    await denied(download(EVE, `certificates/${BOB}/c1.pdf`));
  });

  test('intro video: owner upload and delete (explicit delete rule) work', async () => {
    await allowed(upload(BOB, `user_videos/${BOB}/intro.mp4`, { contentType: 'video/mp4', size: 2 * MB }));
    await denied(upload(EVE, `user_videos/${BOB}/intro.mp4`, { contentType: 'video/mp4' }));
    await denied(deleteObject(EVE, `user_videos/${BOB}/intro.mp4`));
    await allowed(deleteObject(BOB, `user_videos/${BOB}/intro.mp4`));
  });

  test('banner images: admin only', async () => {
    await allowed(upload(ADMIN, 'banner_images/1727000000000.jpg'));
    await denied(upload(ALICE, 'banner_images/1727000000001.jpg'));
  });

  test('unknown paths are denied', async () => {
    await denied(upload(BOB, `misc/${BOB}/a.jpg`));
    await denied(download(null, 'misc/whatever.jpg'));
  });

  test(
    'intro videos only accept video content (they are publicly served)',
    { skip: bug('BUG-t2-26', 'user_videos has no contentType check -> any file type (e.g. text/html) is hosted publicly') },
    async () => {
      await denied(upload(EVE, `user_videos/${EVE}/intro.mp4`, { contentType: 'text/html' }));
    },
  );
});

describe('storage: owners deleting their own files', () => {
  const ownedFiles: Array<[string, string, string]> = [
    ['profile photo (StorageService.deleteProfilePhoto)', BOB, `profile_photos/${BOB}/profile.jpg`],
    ['listing image', ALICE, `listing_images/${ALICE}/l1/0_1.jpg`],
    ['housing image', ALICE, `housing_images/${ALICE}/l1/0_1.jpg`],
    ['verification document', ALICE, `verification_documents/${ALICE}/1_tax_id.jpg`],
    ['certificate file', BOB, `certificates/${BOB}/c1.jpg`],
    ['banner image (admin)', ADMIN, 'banner_images/1.jpg'],
  ];
  for (const [label, owner, path] of ownedFiles) {
    test(
      `the owner can delete a ${label}`,
      { skip: bug('BUG-t2-25', 'write rule dereferences request.resource (null on delete) -> every delete is denied') },
      async () => {
        await upload(owner, path);
        await allowed(deleteObject(owner, path));
      },
    );
  }

  test('another user still cannot delete someone else\'s file', async () => {
    await upload(BOB, `profile_photos/${BOB}/profile.jpg`);
    await denied(deleteObject(EVE, `profile_photos/${BOB}/profile.jpg`));
  });
});
