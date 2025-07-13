import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quiz_model.dart';

class QuizRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all departments from Firestore
  Stream<List<Department>> getDepartments() {
    debugPrint('Fetching departments from Firestore...');
    
    return _firestore.collection('departments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Department(
          id: doc.id,
          name: data['name'] ?? doc.id,
          description: data['description'] ?? 'No description available',
        );
      }).toList();
    });
  }

  // Get courses for a specific department
  Stream<List<Course>> getCoursesForDepartment(String departmentId) {
    debugPrint('Fetching courses for department: $departmentId');
    
    // Get the courses collection for the specified department
    final coursesRef = _firestore
        .collection('departments')
        .doc(departmentId)
        .collection('courses');
    
    return coursesRef.snapshots().handleError((error) {
      debugPrint('Error fetching courses: $error');
      return const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    }).map((snapshot) {
      debugPrint('Found ${snapshot.docs.length} courses for $departmentId');
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint('Course data: $data');
        return Course(
          id: doc.id,
          name: data['name'] ?? doc.id,
          description: data['description'] ?? 'No description available',
        );
      }).toList();
    });
  }

  // Get quizzes for a specific course
  Stream<List<Quiz>> getQuizzesForCourse(String courseId) {
    debugPrint('Fetching quizzes for course: $courseId');
    
    // First, find which department this course belongs to
    return _firestore
        .collectionGroup('courses')
        .snapshots()
        .asyncMap((querySnapshot) async {
      // Find the course with matching ID
      QueryDocumentSnapshot<Map<String, dynamic>>? courseDoc;
      try {
        courseDoc = querySnapshot.docs.firstWhere(
          (doc) => doc.id == courseId,
        );
      } catch (e) {
        debugPrint('No course found with ID: $courseId');
        return <Quiz>[];
      }

      final coursePath = courseDoc.reference.path;
      debugPrint('Found course at path: $coursePath');

      // Extract the department ID from the path (path format: 'departments/{departmentId}/courses/{courseId}')
      final pathParts = coursePath.split('/');
      if (pathParts.length < 4) {
        debugPrint('Invalid course path format: $coursePath');
        return <Quiz>[];
      }

      final departmentId = pathParts[1];
      debugPrint('Found department ID: $departmentId');

      // Now get all quizzes for this course
      final quizzesSnapshot = await _firestore
          .collection('departments')
          .doc(departmentId)
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .get();

      debugPrint('Found ${quizzesSnapshot.docs.length} quizzes for course $courseId');
      
      final quizzes = <Quiz>[];
      
      for (final doc in quizzesSnapshot.docs) {
        final data = doc.data();
        debugPrint('Processing quiz: ${doc.id}');
        
        final questions = <QuizQuestion>[];
        
        if (data['questions'] != null && data['questions'] is List) {
          // Handle multiple questions per quiz
          for (var q in (data['questions'] as List)) {
            questions.add(QuizQuestion(
              question: q['question'] ?? 'No question',
              options: List<String>.from(q['options'] ?? []),
              correctIndex: q['correctIndex'] ?? 0,
              explanation: q['explanation'] ?? '',
            ));
          }
        } else if (data['question'] != null) {
          // Handle case where questions might be stored directly in the quiz document
          questions.add(QuizQuestion(
            question: data['question'] ?? 'No question',
            options: List<String>.from(data['options'] ?? []),
            correctIndex: data['correctIndex'] ?? 0,
            explanation: data['explanation'] ?? '',
          ));
        }
        
        quizzes.add(Quiz(
          id: doc.id,
          title: data['title'] ?? 'Untitled Quiz',
          description: data['description'] ?? 'No description',
          questions: questions,
        ));
      }
      
      return quizzes;
    });
  }

  // Get all quizzes from the Reflective Thinking collection under BSE department
  Future<List<Quiz>> getReflectiveThinkingQuizzes() async {
    try {
      debugPrint('Finding Reflective Thinking course...');
      
      // First, find the Reflective Thinking course in any department
      QuerySnapshot<Map<String, dynamic>> coursesSnapshot;
      try {
        coursesSnapshot = await _firestore
            .collectionGroup('courses')
            .where('name', isEqualTo: 'Reflective Thinking')
            .limit(1)
            .get();
        
        if (coursesSnapshot.docs.isEmpty) {
          debugPrint('No Reflective Thinking course found');
          return [];
        }
      } catch (e) {
        debugPrint('Error finding Reflective Thinking course: $e');
        return [];
      }
      
      final courseDoc = coursesSnapshot.docs.first;
      final coursePath = courseDoc.reference.path;
      debugPrint('Found Reflective Thinking course at: $coursePath');
      
      // Extract department ID from path (format: 'departments/{departmentId}/courses/{courseId}')
      final pathParts = coursePath.split('/');
      if (pathParts.length < 4) {
        debugPrint('Invalid course path format: $coursePath');
        return [];
      }
      
      final departmentId = pathParts[1];
      final courseId = pathParts[3];
      
      debugPrint('Fetching quizzes for department: $departmentId, course: $courseId');
      
      // Now get all quizzes for this course
      final quizzesSnapshot = await _firestore
          .collection('departments')
          .doc(departmentId)
          .collection('courses')
          .doc(courseId)
          .collection('quizzes')
          .get();
      
      debugPrint('Found ${quizzesSnapshot.docs.length} quiz documents');
      
      final quizzes = <Quiz>[];
      
      for (var quizDoc in quizzesSnapshot.docs) {
        final data = quizDoc.data();
        debugPrint('Processing quiz: ${quizDoc.id}');
        
        final questions = <QuizQuestion>[];
        
        if (data['questions'] != null && data['questions'] is List) {
          // Handle multiple questions per quiz
          for (var q in (data['questions'] as List)) {
            questions.add(QuizQuestion(
              question: q['question'] ?? 'No question',
              options: List<String>.from(q['options'] ?? []),
              correctIndex: q['correctIndex'] ?? 0,
              explanation: q['explanation'] ?? '',
            ));
          }
        } else if (data['question'] != null) {
          // Handle single question quiz
          questions.add(QuizQuestion(
            question: data['question'] ?? 'No question',
            options: List<String>.from(data['options'] ?? []),
            correctIndex: data['correctIndex'] ?? 0,
            explanation: data['explanation'] ?? '',
          ));
        }
        
        quizzes.add(Quiz(
          id: quizDoc.id,
          title: data['title'] ?? 'Untitled Quiz',
          description: data['description'] ?? 'No description',
          questions: questions,
        ));
      }
      
      debugPrint('Successfully fetched ${quizzes.length} quizzes');
      return quizzes;
      
    } catch (e, stackTrace) {
      debugPrint('Error in getReflectiveThinkingQuizzes: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  // Get a specific quiz by ID
  Future<Quiz?> getQuiz(String quizId) async {
    try {
      final quizDoc = await _firestore.collection('quizzes').doc(quizId).get();
      if (!quizDoc.exists) {
        debugPrint('Quiz not found: $quizId');
        return null;
      }
      
      final data = quizDoc.data();
      if (data == null) {
        debugPrint('Quiz data is null for quizId: $quizId');
        return null;
      }
      
      final questions = <QuizQuestion>[];
      
      final questionsData = data['questions'] as List?;
      if (questionsData != null) {
        for (var q in questionsData) {
          final qMap = q as Map<String, dynamic>;
          questions.add(QuizQuestion(
            question: qMap['question'] as String? ?? 'No question',
            options: List<String>.from((qMap['options'] as List?) ?? []),
            correctIndex: qMap['correctIndex'] as int? ?? 0,
            explanation: qMap['explanation'] as String? ?? '',
          ));
        }
      }
      
      return Quiz(
        id: quizDoc.id,
        title: data['title'] as String? ?? 'No Title',
        description: data['description'] as String? ?? '',
        questions: questions,
      );
    } catch (e) {
      debugPrint('Error getting quiz: $e');
      return null;
    }
  }
}
