import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

/// Key used to persist the user's "remember me" choice on native platforms,
/// where Firebase Auth has no built-in session-only persistence mode (see
/// [enforceRememberMePreference]).
const String _rememberMePrefsKey = 'auth_remember_me';

/// On native platforms (Android/iOS/desktop), Firebase Auth always persists
/// the session regardless of [FirebaseAuth.setPersistence] — that API only
/// has an effect on web. So unchecking "remember me" there can't stop the
/// session from surviving an app restart at the SDK level; instead, [signIn]
/// and [signInWithSmsCode] record the choice in SharedPreferences, and this
/// function — called once at app startup, before the UI is shown — signs
/// the user back out if they'd asked not to be remembered.
///
/// No-op on web, where [FirebaseAuth.setPersistence] already does the right
/// thing at sign-in time.
///
/// [auth] is injectable for testing; defaults to [FirebaseAuth.instance].
Future<void> enforceRememberMePreference({FirebaseAuth? auth}) async {
  if (kIsWeb) return;
  final firebaseAuth = auth ?? FirebaseAuth.instance;
  if (firebaseAuth.currentUser == null) return;

  final prefs = await SharedPreferences.getInstance();
  final rememberMe = prefs.getBool(_rememberMePrefsKey) ?? true;
  if (!rememberMe) {
    await firebaseAuth.signOut();
  }
}

class AuthService extends ChangeNotifier {
  AuthService(this._auth, this._firestore) {
    _authSub = _auth.authStateChanges().listen((fbUser) {
      if (fbUser != null) {
        _currentUser = AppUser(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          phoneNumber: fbUser.phoneNumber,
        );
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<User?>? _authSub;

  AppUser? _currentUser;
  bool _justRegistered = false;

  /// Returns whether the current user just registered (vs. logged in to an
  /// existing account), and resets the flag. Used to route first-time
  /// registrants through onboarding exactly once.
  bool consumeJustRegistered() {
    final value = _justRegistered;
    _justRegistered = false;
    return value;
  }

  AppUser? get currentUser {
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      return AppUser(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        phoneNumber: fbUser.phoneNumber,
      );
    }
    return _currentUser;
  }

  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map((fbUser) {
        if (fbUser == null) return null;
        return AppUser(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          phoneNumber: fbUser.phoneNumber,
        );
      });

  Future<AppUser> signIn({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    if (kIsWeb) {
      await _auth.setPersistence(
        rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );
    } else {
      await (await SharedPreferences.getInstance())
          .setBool(_rememberMePrefsKey, rememberMe);
    }
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = AppUser(
      uid: credential.user!.uid,
      email: credential.user!.email ?? email,
      phoneNumber: credential.user!.phoneNumber,
    );
    _currentUser = user;
    notifyListeners();
    return user;
  }

  Future<String> verifyPhoneNumber({required String phoneNumber}) async {
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        final userCred = await _auth.signInWithCredential(credential);
        final fbUser = userCred.user;
        if (fbUser != null) {
          _currentUser = AppUser(
            uid: fbUser.uid,
            email: fbUser.email ?? '',
            phoneNumber: fbUser.phoneNumber,
          );
          notifyListeners();
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );
    return completer.future;
  }

  Future<AppUser> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
    bool rememberMe = true,
  }) async {
    if (kIsWeb) {
      await _auth.setPersistence(
        rememberMe ? Persistence.LOCAL : Persistence.SESSION,
      );
    } else {
      await (await SharedPreferences.getInstance())
          .setBool(_rememberMePrefsKey, rememberMe);
    }
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final fbUser = userCredential.user!;
    final user = AppUser(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      phoneNumber: fbUser.phoneNumber,
    );
    _currentUser = user;
    notifyListeners();
    return user;
  }

  Future<AppUser> register({required String email, required String password}) async {
    if (!kIsWeb) {
      // A fresh registration should stay signed in on next launch,
      // regardless of a "don't remember me" choice left over from a
      // previous account's login on this device.
      await (await SharedPreferences.getInstance())
          .setBool(_rememberMePrefsKey, true);
    }
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = AppUser(
      uid: credential.user!.uid,
      email: credential.user!.email ?? email,
      phoneNumber: credential.user!.phoneNumber,
    );
    _currentUser = user;
    _justRegistered = true;
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  /// Re-authenticates user and performs client-side cascading deletion of all user data
  /// across Firestore collections before deleting the Firebase Auth user account.
  Future<void> deleteAccount({required String password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Giriş yapmış bir kullanıcı bulunamadı.');
    }

    final email = user.email;
    if (email != null && email.isNotEmpty) {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
    }

    final uid = user.uid;

    // 1. Delete user profile documents
    try {
      await _firestore.collection('user_profiles').doc(uid).delete();
    } catch (e) {
      debugPrint('Error deleting user profile docs: $e');
    }

    // 2. Delete user's listings
    try {
      final listingsSnap = await _firestore.collection('listings').where('posterId', isEqualTo: uid).get();
      for (final doc in listingsSnap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting listings: $e');
    }

    // 3. Delete user's reports
    try {
      final reportsSnap = await _firestore.collection('reports').where('reporterId', isEqualTo: uid).get();
      for (final doc in reportsSnap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting reports: $e');
    }

    // 4. Delete user's boosts and boost_purchases
    try {
      final boostsSnap = await _firestore.collection('boosts').where('userId', isEqualTo: uid).get();
      for (final doc in boostsSnap.docs) {
        await doc.reference.delete();
      }
      final boostPurchasesSnap = await _firestore.collection('boost_purchases').where('userId', isEqualTo: uid).get();
      for (final doc in boostPurchasesSnap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting boosts: $e');
    }

    // 5. Delete verification requests
    try {
      final verifSnap = await _firestore.collection('verification_requests').where('employerId', isEqualTo: uid).get();
      for (final doc in verifSnap.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting verification requests: $e');
    }

    // 6. Delete conversations and subcollection messages
    try {
      final convsPoster = await _firestore.collection('conversations').where('posterId', isEqualTo: uid).get();
      final convsSeeker = await _firestore.collection('conversations').where('seekerId', isEqualTo: uid).get();
      final allConvs = {...convsPoster.docs, ...convsSeeker.docs};

      for (final doc in allConvs) {
        final messagesSnap = await doc.reference.collection('messages').get();
        for (final msgDoc in messagesSnap.docs) {
          await msgDoc.reference.delete();
        }
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting conversations: $e');
    }

    // 7. Delete Firebase Auth user
    await user.delete();
    _currentUser = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_authSub?.cancel() ?? Future.value());
    super.dispose();
  }
}

final authServiceProvider = ChangeNotifierProvider<AuthService>(
  (ref) => AuthService(FirebaseAuth.instance, FirebaseFirestore.instance),
);

final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges();
});
