import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider that streams authentication state changes
///
/// Returns the current Firebase User when signed in, null when signed out.
/// Automatically updates whenever auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.authStateChanges();
});

/// Provider for the current authenticated user
///
/// Throws an error if accessed when no user is signed in.
/// Use authStateProvider.value to safely check for null.
final currentUserProvider = Provider<User>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) {
        throw Exception('No user is currently signed in');
      }
      return user;
    },
    loading: () => throw Exception('Auth state is loading'),
    error: (err, stack) => throw err,
  );
});

/// Service for handling Firebase Authentication operations
///
/// Provides methods for sign in, sign out, and user registration.
/// Uses Firebase Auth for all authentication flows.
class AuthService {
  final FirebaseAuth _auth;

  AuthService(this._auth);

  /// Current authenticated user, null if not signed in
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  ///
  /// Returns the UserCredential on success.
  /// Throws FirebaseAuthException on failure.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Re-throw with more context if needed
      throw _handleAuthException(e);
    }
  }

  /// Create a new user account with email and password
  ///
  /// Returns the UserCredential on success.
  /// Throws FirebaseAuthException on failure.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out the current user
  ///
  /// Returns Future<void> on success.
  /// Throws FirebaseAuthException on failure.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send password reset email
  ///
  /// Sends a password reset email to the specified address.
  /// Throws FirebaseAuthException on failure.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update the current user's display name
  ///
  /// Updates the user's profile with the provided display name.
  /// Throws an error if no user is signed in.
  Future<void> updateDisplayName(String displayName) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }
    try {
      await user.updateDisplayName(displayName);
      // Reload user to get updated profile
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Update the current user's photo URL
  ///
  /// Updates the user's profile with the provided photo URL.
  /// Throws an error if no user is signed in.
  Future<void> updatePhotoURL(String photoURL) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }
    try {
      await user.updatePhotoURL(photoURL);
      // Reload user to get updated profile
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Send email verification to the current user
  ///
  /// Sends a verification email to the user's email address.
  /// Throws an error if no user is signed in.
  Future<void> sendEmailVerification() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }
    if (user.emailVerified) {
      return; // Already verified
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Reload the current user's data
  ///
  /// Refreshes the user's profile data from Firebase.
  /// Useful after updating profile information.
  Future<void> reloadUser() async {
    final user = currentUser;
    if (user == null) {
      throw Exception('No user is currently signed in');
    }
    try {
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Handle Firebase Auth exceptions with user-friendly messages
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'Kullanıcı bulunamadı';
        break;
      case 'wrong-password':
        message = 'Hatalı şifre';
        break;
      case 'email-already-in-use':
        message = 'Bu e-posta adresi zaten kullanımda';
        break;
      case 'invalid-email':
        message = 'Geçersiz e-posta adresi';
        break;
      case 'weak-password':
        message = 'Şifre çok zayıf';
        break;
      case 'user-disabled':
        message = 'Kullanıcı hesabı devre dışı bırakıldı';
        break;
      case 'too-many-requests':
        message = 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin';
        break;
      case 'operation-not-allowed':
        message = 'Bu işlem izin verilmiyor';
        break;
      case 'network-request-failed':
        message = 'Ağ bağlantısı hatası';
        break;
      default:
        message = 'Bir hata oluştu: ${e.message}';
    }
    return Exception(message);
  }
}

/// Provider for AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthService(auth);
});
