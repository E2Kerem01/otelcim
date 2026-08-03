import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';

class AuthService extends ChangeNotifier {
  AuthService(this._auth, this._firestore) {
    _authSub = _auth.authStateChanges().listen((fbUser) {
      if (fbUser != null) {
        _currentUser = AppUser(uid: fbUser.uid, email: fbUser.email ?? '');
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
      return AppUser(uid: fbUser.uid, email: fbUser.email ?? '');
    }
    return _currentUser;
  }

  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map((fbUser) {
        if (fbUser == null) return null;
        return AppUser(uid: fbUser.uid, email: fbUser.email ?? '');
      });

  Future<AppUser> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = AppUser(uid: credential.user!.uid, email: credential.user!.email ?? email);
    _currentUser = user;
    notifyListeners();
    return user;
  }

  Future<AppUser> register({required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = AppUser(uid: credential.user!.uid, email: credential.user!.email ?? email);
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore user creation warning: $e');
    }
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
      await _firestore.collection('users').doc(uid).delete();
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
    _authSub?.cancel();
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
