import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get the current user's document reference
  DocumentReference<Map<String, dynamic>> get _userDocRef {
    final uid = currentUserId;
    if (uid == null) {
      throw Exception('No authenticated user');
    }
    return _firestore.collection('users').doc(uid);
  }

  // Update the quiz count for the current user
  Future<void> incrementQuizCount() async {
    try {
      await _userDocRef.update({
        'quizzesTaken': FieldValue.increment(1),
        'lastQuizTaken': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update quiz count: $e');
    }
  }

  // Get the current user's data
  Future<AppUser> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      final doc = await _userDocRef.get();
      if (!doc.exists) {
        // Create user document if it doesn't exist
        final newUser = AppUser.fromFirebaseUser(user, {'quizzesTaken': 0});
        await _userDocRef.set(newUser.toMap());
        return newUser;
      }

      return AppUser.fromFirebaseUser(user, doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Stream of user data
  Stream<AppUser> userStream() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) {
        throw Exception('No authenticated user');
      }
      final doc = await _userDocRef.get();
      if (!doc.exists) {
        final newUser = AppUser.fromFirebaseUser(user, {'quizzesTaken': 0});
        await _userDocRef.set(newUser.toMap());
        return newUser;
      }
      return AppUser.fromFirebaseUser(user, doc.data()!);
    });
  }
}
