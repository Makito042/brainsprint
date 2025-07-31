import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'dart:developer' as developer;
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

  // Update the user's highest score if the new score is higher
  Future<void> updateHighestScore(double newScore) async {
    try {
      developer.log('=== updateHighestScore called ===', name: 'UserRepository');
      developer.log('New score to check: $newScore', name: 'UserRepository');
      
      final userDoc = await _userDocRef.get();
      if (!userDoc.exists) {
        developer.log('❌ User document does not exist', name: 'UserRepository');
        return;
      }
      
      final userData = userDoc.data();
      developer.log('User document data: $userData', name: 'UserRepository');
      
      final currentHighest = (userData?['highestScore'] ?? 0).toDouble();
      developer.log('Current highest score: $currentHighest', name: 'UserRepository');
      
      if (newScore > currentHighest) {
        developer.log('🎉 New high score! Updating from $currentHighest to $newScore', name: 'UserRepository');
        
        try {
          await _userDocRef.update({
            'highestScore': newScore,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
          
          // Verify the update
          final updatedDoc = await _userDocRef.get();
          final updatedHighest = (updatedDoc.data()?['highestScore'] ?? 0).toDouble();
          
          if (updatedHighest == newScore) {
            developer.log('✅ Successfully updated highest score to $updatedHighest', name: 'UserRepository');
          } else {
            developer.log('❌ Failed to update highest score. Current value: $updatedHighest', name: 'UserRepository');
          }
        } catch (updateError) {
          developer.log('❌ Error updating document: $updateError', name: 'UserRepository');
          rethrow;
        }
      } else {
        developer.log('ℹ️ Score $newScore is not higher than current highest $currentHighest', name: 'UserRepository');
      }
    } catch (e) {
      developer.log('❌❌❌ CRITICAL ERROR in updateHighestScore: $e', name: 'UserRepository');
      rethrow;
    }
  }

  // Cached stream to prevent recreation
  Stream<AppUser>? _userStream;
  
  // Stream of user data
  Stream<AppUser> getUserStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    // Return the existing stream if we have one
    if (_userStream != null) {
      return _userStream!;
    }

    // Create a new stream
    _userStream = _auth.userChanges().asyncExpand((user) async* {
      if (user == null) {
        _userStream = null;
        return;
      }

      // First, ensure the user document exists
      final doc = await _userDocRef.get();
      if (!doc.exists) {
        // Create a new user document if it doesn't exist
        final appUser = AppUser(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoURL: user.photoURL,
          phoneNumber: user.phoneNumber,
        );
        await _userDocRef.set(appUser.toMap());
        developer.log('Created AppUser with highestScore: ${appUser.highestScore}', name: 'UserRepository');
        yield appUser;
      }
      
      // Then listen for updates
      yield* _userDocRef.snapshots().map((doc) {
        if (!doc.exists) {
          throw Exception('User document was deleted');
        }
        return AppUser.fromFirebaseUser(user, doc.data()!);
      });
    }).asBroadcastStream();
    
    return _userStream!;
  }

  /// Search for users by name or email
  /// Returns a list of users matching the query (excluding the current user)
  Future<List<AppUser>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      // Convert query to lowercase for case-insensitive search
      final searchQuery = query.toLowerCase();
      
      // Search in displayName and email fields
      final snapshot = await _firestore
          .collection('users')
          .where('searchTerms', arrayContains: searchQuery)
          .limit(10)
          .get();

      // Convert documents to AppUser objects
      return snapshot.docs.map((doc) {
        return AppUser.fromFirebaseUser(
          _auth.currentUser!,
          doc.data(),
        );
      }).toList();
    } catch (e) {
      developer.log('Error searching users: $e', name: 'UserRepository');
      rethrow;
    }
  }
}
