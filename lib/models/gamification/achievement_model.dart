import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'achievement_model.g.dart';

enum AchievementType {
  badge,
  streak,
  milestone,
  challenge,
  consistency,
  collaboration,
  mastery,
}

@JsonSerializable()
class UserAchievement {
  final String achievementId;
  final String userId;
  final AchievementType type;
  final String title;
  final String description;
  final String icon;
  final int points;
  final DateTime achievedAt;
  final double progress;
  final dynamic targetValue;
  final bool isUnlocked;
  final Map<String, dynamic>? metadata;

  UserAchievement({
    required this.achievementId,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
    required this.achievedAt,
    this.progress = 0.0,
    this.targetValue,
    this.isUnlocked = false,
    this.metadata,
  });

  // Convert Firestore DocumentSnapshot to UserAchievement
  factory UserAchievement.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return UserAchievement(
      achievementId: snapshot.id,
      userId: data['userId'] as String,
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == 'AchievementType.${data['type']}',
        orElse: () => AchievementType.badge,
      ),
      title: data['title'] as String,
      description: data['description'] as String,
      icon: data['icon'] as String,
      points: data['points'] as int,
      achievedAt: (data['achievedAt'] as Timestamp).toDate(),
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      targetValue: data['targetValue'],
      isUnlocked: data['isUnlocked'] as bool? ?? false,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert UserAchievement to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'icon': icon,
      'points': points,
      'achievedAt': Timestamp.fromDate(achievedAt),
      'progress': progress,
      'targetValue': targetValue,
      'isUnlocked': isUnlocked,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // JSON serialization (kept for compatibility)
  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      achievementId: json['achievementId'] as String,
      userId: json['userId'] as String,
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == 'AchievementType.${json['type']}',
        orElse: () => AchievementType.badge,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      points: json['points'] as int,
      achievedAt: DateTime.parse(json['achievedAt'] as String),
      progress: (json['progress'] as num).toDouble(),
      targetValue: json['targetValue'],
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'description': description,
      'icon': icon,
      'points': points,
      'achievedAt': achievedAt.toIso8601String(),
      'progress': progress,
      'targetValue': targetValue,
      'isUnlocked': isUnlocked,
      'metadata': metadata,
    };
  }

  UserAchievement copyWith({
    String? achievementId,
    String? userId,
    AchievementType? type,
    String? title,
    String? description,
    String? icon,
    int? points,
    DateTime? achievedAt,
    double? progress,
    dynamic targetValue,
    bool? isUnlocked,
    Map<String, dynamic>? metadata,
  }) {
    return UserAchievement(
      achievementId: achievementId ?? this.achievementId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      points: points ?? this.points,
      achievedAt: achievedAt ?? this.achievedAt,
      progress: progress ?? this.progress,
      targetValue: targetValue ?? this.targetValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      metadata: metadata ?? this.metadata,
    );
  }
}
