#!/usr/bin/env node

import assert from 'node:assert/strict';
import {createRequire} from 'node:module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

const minPrefix = 2;
const maxPrefix = 15;
const maxKeywords = 150;
const batchSize = 400;

const fold = new Map([
  ['ç', 'c'],
  ['ğ', 'g'],
  ['ı', 'i'],
  ['i̇', 'i'],
  ['ö', 'o'],
  ['ş', 's'],
  ['ü', 'u'],
  ['â', 'a'],
  ['î', 'i'],
  ['û', 'u'],
]);

function normalizeForSearch(input) {
  const lower = input.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
  let normalized = '';
  for (const character of lower) normalized += fold.get(character) ?? character;
  return normalized.replaceAll('\u0307', '');
}

function words(normalized) {
  return normalized.split(/[^a-z0-9@._+-]+/).filter((word) => word.length > 0);
}

function addPrefixes(output, word) {
  if (word.length < minPrefix) return;
  const end = Math.min(word.length, maxPrefix);
  for (let length = minPrefix; length <= end; length++) {
    output.add(word.slice(0, length));
  }
}

// Keep this implementation in lockstep with lib/shared/utils/search_keywords.dart.
function buildSearchKeywords(fields) {
  const output = new Set();
  for (const field of fields) {
    if (typeof field !== 'string' || field.trim().length === 0) continue;
    const normalized = normalizeForSearch(field.trim());
    if (normalized.includes('@')) {
      output.add(normalized);
      addPrefixes(output, normalized.split('@')[0]);
    }
    for (const word of words(normalized)) {
      for (const part of word.split(/[@._+-]+/)) addPrefixes(output, part);
    }
  }
  return [...output].sort().slice(0, maxKeywords);
}

function searchToken(query) {
  const normalized = normalizeForSearch(query.trim());
  if (normalized.includes('@') && !normalized.includes(' ')) return normalized;
  const searchableWords = words(normalized)
    .filter((word) => word.length >= minPrefix)
    .sort((a, b) => b.length - a.length);
  if (searchableWords.length === 0) return null;
  const word = searchableWords[0];
  return word.length > maxPrefix ? word.slice(0, maxPrefix) : word;
}

function valuesAreEqual(actual, expected) {
  return Array.isArray(actual) &&
    actual.length === expected.length &&
    actual.every((value, index) => value === expected[index]);
}

function fieldsForDocument(collection, data) {
  if (collection === 'user_profiles') {
    return [data.displayName, data.email, data.hotelName, data.phoneNumber];
  }
  return [data.title, data.posterName, data.city, data.location, data.region];
}

async function collectChanges(db, collection) {
  const snapshot = await db.collection(collection).get();
  const changes = [];
  for (const doc of snapshot.docs) {
    const keywords = buildSearchKeywords(fieldsForDocument(collection, doc.data()));
    if (!valuesAreEqual(doc.data().searchKeywords, keywords)) {
      changes.push({ref: doc.ref, keywords});
    }
  }
  return {total: snapshot.size, changes};
}

async function applyChanges(db, changes) {
  for (let offset = 0; offset < changes.length; offset += batchSize) {
    const batch = db.batch();
    for (const change of changes.slice(offset, offset + batchSize)) {
      batch.update(change.ref, {searchKeywords: change.keywords});
    }
    await batch.commit();
  }
}

function runSelfTest() {
  assert.deepEqual(
    buildSearchKeywords(['Ayşe Aday', 'ayse@x.test']),
    ['ad', 'ada', 'aday', 'ay', 'ays', 'ayse', 'ayse@x.test', 'te', 'tes', 'test'],
  );
  assert.equal(searchToken('AYŞE'), 'ayse');
  assert.equal(normalizeForSearch('İ I ÇĞŞÜ ÂÎÛ'), 'i i cgsu aiu');
  console.log('search keyword self-test: OK');
}

async function main() {
  const args = new Set(process.argv.slice(2));
  if (args.has('--self-test')) {
    runSelfTest();
    return;
  }

  if (process.env.FIRESTORE_EMULATOR_HOST) {
    process.env.GCLOUD_PROJECT ||= 'otelcim';
    console.log(`Firestore emulator: ${process.env.FIRESTORE_EMULATOR_HOST}`);
  }
  admin.initializeApp({projectId: process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT || 'otelcim'});
  const db = admin.firestore();
  const apply = args.has('--apply');

  for (const collection of ['user_profiles', 'listings']) {
    const result = await collectChanges(db, collection);
    console.log(`${collection}: ${result.total} belge, ${result.changes.length} belge değişecek`);
    if (apply) {
      await applyChanges(db, result.changes);
      console.log(`${collection}: ${result.changes.length} belge güncellendi`);
    }
  }
  if (!apply) console.log('Dry-run tamamlandı; yazmak için --apply kullanın.');
}

await main();
