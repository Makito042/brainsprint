import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';
import 'package:flutter/foundation.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all quizzes
  Future<List<Quiz>> getQuizzes() async {
    try {
      final querySnapshot = await _firestore.collection('quizzes').get();
      return querySnapshot.docs.map((doc) => Quiz.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('Error getting quizzes: $e');
      return [];
    }
  }

  // Get a specific quiz by ID
  Future<Quiz?> getQuiz(String quizId) async {
    try {
      final doc = await _firestore.collection('quizzes').doc(quizId).get();
      if (doc.exists) {
        return Quiz.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting quiz: $e');
      return null;
    }
  }

  // Add a new quiz (for admin use)
  Future<void> addQuiz(Quiz quiz) async {
    try {
      await _firestore.collection('quizzes').doc(quiz.id).set(quiz.toMap());
    } catch (e) {
      debugPrint('Error adding quiz: $e');
      rethrow;
    }
  }
}
