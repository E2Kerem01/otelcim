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
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
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
