import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:brainsprint/models/quiz_model.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Create Firestore instance
  final firestore = FirebaseFirestore.instance;
  
  // Define your quizzes
  final quizzes = [
    Quiz(
      id: 'quiz1',
      title: 'Quiz 1: Foundations of Reflective Thinking',
      description: 'Test your understanding of basic reflective thinking concepts',
      questions: [
        QuizQuestion(
          question: 'What is the primary purpose of reflective thinking?',
          options: [
            'To memorize information',
            'To analyze and evaluate experiences',
            'To follow instructions precisely',
            'To complete tasks quickly',
          ],
          correctIndex: 1,
          explanation: 'Reflective thinking involves analyzing and evaluating experiences to gain deeper understanding and learning.',
        ),
        QuizQuestion(
          question: 'Which of the following is NOT a stage of the reflective thinking process?',
          options: [
            'Description',
            'Feelings',
            'Evaluation',
            'Memorization',
          ],
          correctIndex: 3,
          explanation: 'Memorization is not part of the reflective thinking process, which focuses on understanding rather than rote learning.',
        ),
        QuizQuestion(
          question: 'What does the "Description" stage of reflection involve?',
          options: [
            'Judging the experience',
            'Planning future actions',
            'Recalling what happened',
            'Expressing emotions',
          ],
          correctIndex: 2,
          explanation: 'The Description stage involves objectively recalling and describing what happened during the experience.',
        ),
        // Add more questions from the original list...
      ],
    ),
    Quiz(
      id: 'quiz2',
      title: 'Quiz 2: Advanced Reflective Practices',
      description: 'Test your knowledge of advanced reflective thinking techniques',
      questions: [
        QuizQuestion(
          question: 'What is the difference between reflection-in-action and reflection-on-action?',
          options: [
            'One is done during the experience, the other after',
            'One is formal, the other is informal',
            'One is for positive experiences, one for negative',
            'There is no difference',
          ],
          correctIndex: 0,
          explanation: 'Reflection-in-action occurs during the experience, while reflection-on-action occurs after the experience has taken place.',
        ),
        // Add more questions from the second quiz...
      ],
    ),
  ];

  // Upload quizzes to Firestore
  try {
    final batch = firestore.batch();
    final quizzesRef = firestore.collection('quizzes');
    
    for (final quiz in quizzes) {
      final quizRef = quizzesRef.doc(quiz.id);
      batch.set(quizRef, quiz.toMap());
    }
    
    await batch.commit();
    debugPrint('Successfully migrated ${quizzes.length} quizzes to Firestore');
  } catch (e) {
    debugPrint('Error migrating quizzes: $e');
  } finally {
    // Close the app after migration
    exit(0);
  }
}
}
