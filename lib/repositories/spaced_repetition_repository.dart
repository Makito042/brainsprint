import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/spaced_repetition_model.dart';

class SpacedRepetitionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> savePreferences(String userId, SpacedRepetitionPreferences preferences) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('spaced_repetition')
        .doc('preferences')
        .set(preferences.toMap());
  }

  Stream<SpacedRepetitionPreferences?> getPreferencesStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('spaced_repetition')
        .doc('preferences')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return SpacedRepetitionPreferences.fromMap(snapshot.data()!);
    });
  }

  Future<void> updateNextReviewDate(String userId, String topicId, DateTime date) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('spaced_repetition')
        .doc('preferences')
        .update({
      'nextReviewDates.$topicId': date.toIso8601String(),
    });
  }

  Future<void> updateMasteryLevel(String userId, String topicId, int level) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('spaced_repetition')
        .doc('preferences')
        .update({
      'masteryLevels.$topicId': level,
    });
  }
}
