import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Firestore instance screens read directly (e.g. admin query builders).
/// Override in tests with a `FakeFirebaseFirestore` instead of touching
/// `FirebaseFirestore.instance`, which needs an initialized Firebase app.
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
