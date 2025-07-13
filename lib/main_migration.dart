import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Models for quiz data
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}

class Quiz {
  final String id;
  final String title;
  final String description;
  final List<QuizQuestion> questions;

  const Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

// Helper function to add quizzes to the Reflective Thinking course
Future<void> _addReflectiveThinkingQuizzes(CollectionReference quizzesRef) async {
  final batch = FirebaseFirestore.instance.batch();
  
  // Quiz 1: Introduction to Reflective Thinking
  final quiz1Ref = quizzesRef.doc('reflective_thinking_1');
  final quiz1 = Quiz(
    id: 'reflective_thinking_1',
    title: 'Reflective Thinking Basics',
    description: 'Test your understanding of reflective thinking concepts',
    questions: [
      QuizQuestion(
        question: 'What is the first step in the reflective thinking process?',
        options: [
          'Identifying the problem',
          'Gathering information',
          'Analyzing the situation',
          'Drawing conclusions'
        ],
        correctIndex: 0,
        explanation: 'The first step is always to clearly identify and define the problem.'
      ),
      QuizQuestion(
        question: 'Which of these is NOT a characteristic of reflective thinking?',
        options: [
          'Critical analysis',
          'Emotional reaction',
          'Self-awareness',
          'Open-mindedness'
        ],
        correctIndex: 1,
        explanation: 'Reflective thinking involves controlling emotional reactions, not being driven by them.'
      ),
      QuizQuestion(
        question: 'What is the primary purpose of reflective thinking?',
        options: [
          'To memorize information',
          'To analyze and evaluate experiences',
          'To follow instructions precisely',
          'To complete tasks quickly'
        ],
        correctIndex: 1,
        explanation: 'Reflective thinking involves analyzing and evaluating experiences to gain deeper understanding and learning.'
      ),
    ],
  );
  batch.set(quiz1Ref, quiz1.toMap());

  // Quiz 2: Advanced Reflective Practice
  final quiz2Ref = quizzesRef.doc('reflective_thinking_2');
  final quiz2 = Quiz(
    id: 'reflective_thinking_2',
    title: 'Advanced Reflective Practice',
    description: 'Deepen your reflective thinking skills with advanced concepts',
    questions: [
      QuizQuestion(
        question: 'What is the purpose of the "What? So What? Now What?" model?',
        options: [
          'To memorize facts',
          'To structure reflective writing',
          'To speed up decision making',
          'To avoid deep thinking'
        ],
        correctIndex: 1,
        explanation: 'This model provides a simple structure for reflection, helping to organize thoughts and insights.'
      ),
      QuizQuestion(
        question: 'Which of these is essential for deep reflection?',
        options: [
          'Rushing through the process',
          'Focusing only on positive experiences',
          'Challenging your own assumptions',
          'Avoiding personal feelings'
        ],
        correctIndex: 2,
        explanation: 'Deep reflection requires examining and challenging your own assumptions and beliefs.'
      ),
      QuizQuestion(
        question: 'What is the difference between reflection-in-action and reflection-on-action?',
        options: [
          'One is formal, the other informal',
          'One is during the experience, one after',
          'One is for positive experiences, one for negative',
          'There is no difference'
        ],
        correctIndex: 1,
        explanation: 'Reflection-in-action occurs during the experience, while reflection-on-action occurs afterward.'
      ),
    ],
  );
  batch.set(quiz2Ref, quiz2.toMap());

  await batch.commit();
  print('✅ Added reflective thinking quizzes');
}

/// Creates the basic department and course structure in Firestore
/// 
/// This function will:
/// 1. Create the BSE department with Reflective Thinking course
/// 2. Create the BEL department with Reflective Thinking course
Future<void> migrateFirestore() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // 1. Create BSE department with Reflective Thinking course
    await _createDepartmentWithCourse(
      firestore,
      departmentId: 'BSE',
      departmentName: 'BSE',
      departmentFullName: 'Bachelor of Science in Engineering',
      departmentDescription: 'Software Engineering Program',
    );
    
    // 2. Create BEL department with Reflective Thinking course
    await _createDepartmentWithCourse(
      firestore,
      departmentId: 'BEL',
      departmentName: 'BEL',
      departmentFullName: 'Business and Entrepreneurship Leadership',
      departmentDescription: 'Business and Entrepreneurship Leadership Program',
    );
    
    print('✅ Successfully created departments and courses');
  } catch (e) {
    print('❌ Error during migration: $e');
    rethrow;
  }
}

/// Helper function to create a department with a Reflective Thinking course
Future<void> _createDepartmentWithCourse(
  FirebaseFirestore firestore, {
  required String departmentId,
  required String departmentName,
  required String departmentFullName,
  required String departmentDescription,
}) async {
  final batch = firestore.batch();
  
  // Create department
  final deptRef = firestore.collection('departments').doc(departmentId);
  batch.set(deptRef, {
    'name': departmentName,
    'fullName': departmentFullName,
    'description': departmentDescription,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  
  // Create or update Reflective Thinking course
  // Create or update Reflective Thinking course
  final courseRef = deptRef.collection('courses').doc('reflective_thinking');
  batch.set(courseRef, {
    'name': 'Reflective Thinking',
    'description': 'Develop critical thinking and self-reflection skills',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
  
  await batch.commit();
  
  // Add quizzes after the batch is committed
  await _addReflectiveThinkingQuizzes(courseRef.collection('quizzes'));
  
  print('✅ Created $departmentName department with Reflective Thinking course and quizzes');
}

void main() async {
  // Initialize Firebase
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Run the migration
  print('🚀 Starting Firestore migration...');
  await migrateFirestore();
  
  // Show completion message
  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('Migration completed successfully!'),
      ),
    ),
  ));
}