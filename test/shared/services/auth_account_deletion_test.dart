import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:otelcim/shared/services/auth_service.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockAuthCredential extends Mock implements AuthCredential {}

void main() {
  setUpAll(() {
    registerFallbackValue(MockAuthCredential());
  });

  group('AuthService deleteAccount', () {
    late MockFirebaseAuth auth;
    late MockUser user;
    late FakeFirebaseFirestore db;

    setUp(() {
      auth = MockFirebaseAuth();
      user = MockUser();
      db = FakeFirebaseFirestore();

      when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(user));
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.uid).thenReturn('user_to_delete');
      when(() => user.email).thenReturn('user@example.com');
    });

    test('re-authentication failure throws exception and aborts account deletion', () async {
      when(() => user.reauthenticateWithCredential(any())).thenThrow(
        FirebaseAuthException(code: 'wrong-password', message: 'Hatalı şifre'),
      );

      final service = AuthService(auth, db);

      expect(
        () => service.deleteAccount(password: 'wrong_pass'),
        throwsA(isA<FirebaseAuthException>()),
      );

      verifyNever(() => user.delete());
      service.dispose();
    });

    test('successful re-authentication triggers cascading deletion of all user data in Firestore and deletes Auth user', () async {
      const uid = 'user_to_delete';

      // Seed Firestore with user data across all collections
      await db.collection('user_profiles').doc(uid).set({'id': uid, 'email': 'user@example.com'});
      await db.collection('listings').doc('listing_1').set({'posterId': uid, 'title': 'İlan 1'});
      await db.collection('reports').doc('report_1').set({'reporterId': uid, 'reason': 'scam'});
      await db.collection('boosts').doc('boost_1').set({'userId': uid, 'price': 99.0});
      await db.collection('boost_purchases').doc('purchase_1').set({'userId': uid, 'price': 99.0});
      await db.collection('verification_requests').doc('verif_1').set({'employerId': uid, 'hotelName': 'Hotel X'});

      // Conversation and subcollection message
      final convRef = db.collection('conversations').doc('conv_1');
      await convRef.set({'posterId': uid, 'seekerId': 'other_user', 'listingTitle': 'İlan'});
      await convRef.collection('messages').doc('msg_1').set({'senderId': uid, 'text': 'Merhaba'});

      when(() => user.reauthenticateWithCredential(any())).thenAnswer((_) async => MockUserCredential());
      when(() => user.delete()).thenAnswer((_) async {});

      final service = AuthService(auth, db);
      await service.deleteAccount(password: 'correct_pass');

      // Verify cascading deletion across all collections
      expect((await db.collection('user_profiles').doc(uid).get()).exists, isFalse);
      expect((await db.collection('listings').doc('listing_1').get()).exists, isFalse);
      expect((await db.collection('reports').doc('report_1').get()).exists, isFalse);
      expect((await db.collection('boosts').doc('boost_1').get()).exists, isFalse);
      expect((await db.collection('boost_purchases').doc('purchase_1').get()).exists, isFalse);
      expect((await db.collection('verification_requests').doc('verif_1').get()).exists, isFalse);

      expect((await convRef.get()).exists, isFalse);
      expect((await convRef.collection('messages').doc('msg_1').get()).exists, isFalse);

      // Verify Firebase Auth user.delete() was called
      verify(() => user.delete()).called(1);
      service.dispose();
    });
  });
}

class MockUserCredential extends Mock implements UserCredential {}
