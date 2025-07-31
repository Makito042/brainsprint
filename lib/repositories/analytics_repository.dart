import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/analytics_models.dart';

class AnalyticsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's topic mastery data
  Stream<List<TopicMastery>> getUserTopicMastery() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('userAnalytics')
        .doc(userId)
        .collection('topicMastery')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TopicMastery.fromMap(doc.data()))
            .toList());
  }

  // Get user's knowledge gaps
  Stream<List<KnowledgeGap>> getUserKnowledgeGaps() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('userAnalytics')
        .doc(userId)
        .collection('knowledgeGaps')
        .orderBy('gapSeverity', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => KnowledgeGap.fromMap(doc.data()))
            .toList());
  }

  // Get study recommendations
  Stream<List<StudyRecommendation>> getStudyRecommendations() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('userAnalytics')
        .doc(userId)
        .collection('recommendations')
        .orderBy('recommendedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudyRecommendation.fromMap(doc.data()))
            .toList());
  }

  // Get peer comparison data (anonymized)
  Future<Map<String, dynamic>> getPeerComparisonData(String topicId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    // Get current user's academic level
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final academicLevel = userDoc.data()?['academicLevel'] ?? 'default';

    // Get peer data (anonymized)
    final peerData = await _firestore
        .collection('analytics')
        .doc('peerComparisons')
        .collection(academicLevel)
        .doc(topicId)
        .get();

    return peerData.data() ?? {};
  }

  // Update user's quiz attempt in analytics
  Future<void> recordQuizAttempt({
    required String quizId,
    required String topicId,
    required int score,
    required int totalQuestions,
    required Map<String, dynamic> questionResults,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final batch = _firestore.batch();
    final userAnalyticsRef = _firestore.collection('userAnalytics').doc(userId);
    final timestamp = FieldValue.serverTimestamp();

    // Record the quiz attempt
    batch.set(
      userAnalyticsRef
          .collection('quizAttempts')
          .doc(DateTime.now().millisecondsSinceEpoch.toString()),
      {
        'quizId': quizId,
        'topicId': topicId,
        'score': score,
        'totalQuestions': totalQuestions,
        'timestamp': timestamp,
      },
    );

    // Update topic mastery
    final topicMasteryRef = userAnalyticsRef
        .collection('topicMastery')
        .doc(topicId);

    batch.set(
      topicMasteryRef,
      {
        'topicId': topicId,
        'lastUpdated': timestamp,
        'totalQuestions': FieldValue.increment(totalQuestions),
        'correctAnswers': FieldValue.increment(score),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    // Trigger analysis of knowledge gaps
    _analyzeKnowledgeGaps(userId, topicId, questionResults);
  }

  // Analyze knowledge gaps based on quiz results
  Future<void> _analyzeKnowledgeGaps(
    String userId,
    String topicId,
    Map<String, dynamic> questionResults,
  ) async {
    // This would be more sophisticated in a real implementation
    final incorrectQuestions = questionResults.entries
        .where((e) => !e.value['isCorrect'])
        .map((e) => e.key)
        .toList();

    if (incorrectQuestions.isNotEmpty) {
      await _firestore
          .collection('userAnalytics')
          .doc(userId)
          .collection('knowledgeGaps')
          .doc(topicId)
          .set(
        {
          'topicId': topicId,
          'gapSeverity': incorrectQuestions.length / questionResults.length,
          'relatedConcepts': incorrectQuestions,
          'identifiedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }
}
