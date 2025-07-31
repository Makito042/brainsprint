// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAchievement _$UserAchievementFromJson(Map<String, dynamic> json) =>
    UserAchievement(
      achievementId: json['achievementId'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$AchievementTypeEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      points: (json['points'] as num).toInt(),
      achievedAt: DateTime.parse(json['achievedAt'] as String),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      targetValue: json['targetValue'],
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UserAchievementToJson(UserAchievement instance) =>
    <String, dynamic>{
      'achievementId': instance.achievementId,
      'userId': instance.userId,
      'type': _$AchievementTypeEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'icon': instance.icon,
      'points': instance.points,
      'achievedAt': instance.achievedAt.toIso8601String(),
      'progress': instance.progress,
      'targetValue': instance.targetValue,
      'isUnlocked': instance.isUnlocked,
      'metadata': instance.metadata,
    };

const _$AchievementTypeEnumMap = {
  AchievementType.badge: 'badge',
  AchievementType.streak: 'streak',
  AchievementType.milestone: 'milestone',
  AchievementType.challenge: 'challenge',
  AchievementType.consistency: 'consistency',
  AchievementType.collaboration: 'collaboration',
  AchievementType.mastery: 'mastery',
};
