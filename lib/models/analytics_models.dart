import 'package:cloud_firestore/cloud_firestore.dart';

class TopicMastery {
  final String topicId;
  final String topicName;
  final double masteryScore; // 0.0 to 1.0
  final int totalQuestions;
  final int correctAnswers;
  final DateTime lastUpdated;
  final List<SubTopicMastery> subTopics;

  TopicMastery({
    required this.topicId,
    required this.topicName,
    required this.masteryScore,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.lastUpdated,
    required this.subTopics,
  });

  factory TopicMastery.fromMap(Map<String, dynamic> map) {
    return TopicMastery(
      topicId: map['topicId'] ?? '',
      topicName: map['topicName'] ?? 'Untitled Topic',
      masteryScore: (map['masteryScore'] ?? 0.0).toDouble(),
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subTopics: (map['subTopics'] as List<dynamic>?)
              ?.map((e) => SubTopicMastery.fromMap(Map<String, dynamic>.from(e)))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'topicName': topicName,
      'masteryScore': masteryScore,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'subTopics': subTopics.map((e) => e.toMap()).toList(),
    };
  }
}

class SubTopicMastery {
  final String subTopicId;
  final String subTopicName;
  final double masteryScore;
  final int totalQuestions;
  final int correctAnswers;

  SubTopicMastery({
    required this.subTopicId,
    required this.subTopicName,
    required this.masteryScore,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  factory SubTopicMastery.fromMap(Map<String, dynamic> map) {
    return SubTopicMastery(
      subTopicId: map['subTopicId'] ?? '',
      subTopicName: map['subTopicName'] ?? 'Untitled Subtopic',
      masteryScore: (map['masteryScore'] ?? 0.0).toDouble(),
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subTopicId': subTopicId,
      'subTopicName': subTopicName,
      'masteryScore': masteryScore,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
    };
  }
}

class KnowledgeGap {
  final String topicId;
  final String topicName;
  final double gapSeverity; // 0.0 to 1.0
  final List<String> relatedConcepts;
  final DateTime identifiedAt;

  KnowledgeGap({
    required this.topicId,
    required this.topicName,
    required this.gapSeverity,
    required this.relatedConcepts,
    DateTime? identifiedAt,
  }) : identifiedAt = identifiedAt ?? DateTime.now();

  factory KnowledgeGap.fromMap(Map<String, dynamic> map) {
    return KnowledgeGap(
      topicId: map['topicId'] ?? '',
      topicName: map['topicName'] ?? 'Untitled Topic',
      gapSeverity: (map['gapSeverity'] ?? 0.0).toDouble(),
      relatedConcepts: List<String>.from(map['relatedConcepts'] ?? []),
      identifiedAt: (map['identifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'topicName': topicName,
      'gapSeverity': gapSeverity,
      'relatedConcepts': relatedConcepts,
      'identifiedAt': Timestamp.fromDate(identifiedAt),
    };
  }
}

class StudyRecommendation {
  final String id;
  final String title;
  final String description;
  final String topicId;
  final String topicName;
  final RecommendationType type;
  final DateTime recommendedAt;
  final Map<String, dynamic> metadata;

  StudyRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.topicId,
    required this.topicName,
    required this.type,
    DateTime? recommendedAt,
    Map<String, dynamic>? metadata,
  })  : recommendedAt = recommendedAt ?? DateTime.now(),
        metadata = metadata ?? {};

  factory StudyRecommendation.fromMap(Map<String, dynamic> map) {
    return StudyRecommendation(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      topicId: map['topicId'] ?? '',
      topicName: map['topicName'] ?? '',
      type: RecommendationType.values.firstWhere(
        (e) => e.toString() == 'RecommendationType.${map['type']}',
        orElse: () => RecommendationType.study,
      ),
      recommendedAt: (map['recommendedAt'] as Timestamp?)?.toDate(),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'topicId': topicId,
      'topicName': topicName,
      'type': type.toString().split('.').last,
      'recommendedAt': Timestamp.fromDate(recommendedAt),
      'metadata': metadata,
    };
  }
}

enum RecommendationType {
  study,
  practice,
  review,
  examPrep,
  resource,
  timeManagement,
}
