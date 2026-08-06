import 'package:flutter_test/flutter_test.dart';
import 'package:otelcim/shared/utils/referral_code.dart';

void main() {
  group('generateReferralCode', () {
    test('returns the first 8 characters uppercased', () {
      expect(generateReferralCode('abc123def456'), 'ABC123DE');
    });

    test('is deterministic for the same uid', () {
      const uid = 'xyz987uvw654';
      expect(generateReferralCode(uid), generateReferralCode(uid));
    });

    test('uppercases uids that are already mixed case', () {
      expect(generateReferralCode('AbCdEfGh1234'), 'ABCDEFGH');
    });

    test('returns the whole uid uppercased when shorter than 8 characters', () {
      expect(generateReferralCode('ab1'), 'AB1');
    });

    test('returns exactly 8 characters when uid is exactly 8 characters', () {
      expect(generateReferralCode('abcd1234'), 'ABCD1234');
    });

    test('different uids produce different codes', () {
      expect(
        generateReferralCode('userone1234'),
        isNot(equals(generateReferralCode('usertwo5678'))),
      );
    });
  });
}
