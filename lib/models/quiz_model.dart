import 'package:cloud_firestore/cloud_firestore.dart';

class Department {
  final String id;
  final String name;
  final String description;

  const Department({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Department.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Department(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
    };
  }
}

class Course {
  final String id;
  final String name;
  final String description;

  const Course({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Course.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
    };
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation = '',
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] as String,
      options: List<String>.from(json['options'] as List),
      correctIndex: json['correctIndex'] as int,
      explanation: (json['explanation'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
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

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final questionsData = List<Map<String, dynamic>>.from(data['questions'] ?? []);
    
    return Quiz(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      questions: questionsData
          .map((q) => QuizQuestion.fromJson(Map<String, dynamic>.from(q)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  int get questionCount => questions.length;
}
