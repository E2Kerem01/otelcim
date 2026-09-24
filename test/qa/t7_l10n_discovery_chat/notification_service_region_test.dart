import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/shared/services/notification_service.dart';

void main() {
  group('NotificationService regionTopicName & Topic Parity Tests', () {
    test('regionTopicName maps standard inputs to expected FCM topics (Dart client table)', () {
      // Dart's String.toLowerCase maps 'İ' (U+0130) to a plain 'i', so the
      // client produces 'region_izmir'. (JS differs — see BUG-t7-12 below.)
      final testCases = <String, String>{
        'Muğla': 'region_mu_la',
        'İzmir': 'region_izmir',
        ' Antalya ': 'region_antalya',
        '': 'region_',
        'a/b': 'region_a_b',
        'Bodrum': 'region_bodrum',
        'Kuşadası': 'region_ku_adas_',
        'Kapadokya': 'region_kapadokya',
        'Istanbul': 'region_istanbul',
        'Trabzon': 'region_trabzon',
        'Çeşme': 'region__e_me',
      };

      for (final entry in testCases.entries) {
        final input = entry.key;
        final expected = entry.value;
        final actual = regionTopicName(input);
        expect(
          actual,
          equals(expected),
          reason: 'Input "$input" must map to topic "$expected" but got "$actual"',
        );
      }
    });

    test('regionTopicName replaces emojis with underscores', () {
      final topic = regionTopicName('🏖️');
      expect(topic.startsWith('region_'), isTrue);
      // All emoji codepoints should be replaced by underscores
      expect(topic, equals('region____'));
    });

    test('regionTopicName trims leading and trailing whitespace', () {
      expect(regionTopicName('   Marmaris   '), equals('region_marmaris'));
      expect(regionTopicName('\tFethiye\n'), equals('region_fethiye'));
    });

    test('regionTopicName preserves valid FCM topic characters (-_.~%)', () {
      expect(regionTopicName('region-1_zone.a~50%'), equals('region_region-1_zone.a~50%'));
    });

    test('regionTopicName collision analysis (different inputs produce identical topic)', () {
      // "Muğla" has 'ğ' replaced with '_', making it identical to "Mu_la"
      final topicMugla = regionTopicName('Muğla');
      final topicMuUnderscoreLa = regionTopicName('Mu_la');
      expect(topicMugla, equals(topicMuUnderscoreLa),
          reason: 'Documented collision: Turkish special char "ğ" collides with literal underscore "_"');

      // "Marmaris!" and "Marmaris?" both become "region_marmaris_"
      expect(regionTopicName('Marmaris!'), equals(regionTopicName('Marmaris?')));
    });

    test('regionTopicName produces identical topic names for "İzmir" and "izmir" on the Dart client', () {
      expect(regionTopicName('İzmir'), equals(regionTopicName('izmir')));
    });

    test(
      'client topic for "İzmir" matches the Cloud Functions topic (functions/src/index.ts:209)',
      () {
        // The server runs the same algorithm in JavaScript:
        //   region.trim().toLowerCase().replace(/[^a-z0-9-_.~%]/g, "_")
        // Per ECMAScript SpecialCasing, JS "İ".toLowerCase() is "i" + U+0307
        // (combining dot above). U+0307 is outside the allowed set, so the
        // server publishes to "region_i_zmir". Dart lowercases "İ" to a plain
        // "i" and subscribes the client to "region_izmir" — the topics never
        // meet, so urgent-listing pushes for "İzmir" are never delivered.
        const serverTopic = 'region_i_zmir';
        expect(regionTopicName('İzmir'), equals(serverTopic));
      },
      skip:
          'BUG-t7-12: Dart client subscribes to region_izmir but Cloud Functions (JS toLowerCase) publishes to region_i_zmir for "İzmir" (notification_service.dart:14-20 vs functions/src/index.ts:209)',
    );
  });
}
