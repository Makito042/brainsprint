// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'challenge_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Challenge _$ChallengeFromJson(Map<String, dynamic> json) => Challenge(
  challengeId: json['challengeId'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  type: $enumDecode(_$ChallengeTypeEnumMap, json['type']),
  status: $enumDecode(_$ChallengeStatusEnumMap, json['status']),
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: DateTime.parse(json['endDate'] as String),
  rewardPoints: (json['rewardPoints'] as num).toInt(),
  requirements: json['requirements'] as Map<String, dynamic>,
  participants: (json['participants'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  teamIds: (json['teamIds'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  courseId: json['courseId'] as String?,
  createdBy: json['createdBy'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ChallengeToJson(Challenge instance) => <String, dynamic>{
  'challengeId': instance.challengeId,
  'title': instance.title,
  'description': instance.description,
  'type': _$ChallengeTypeEnumMap[instance.type]!,
  'status': _$ChallengeStatusEnumMap[instance.status]!,
  'startDate': instance.startDate.toIso8601String(),
  'endDate': instance.endDate.toIso8601String(),
  'rewardPoints': instance.rewardPoints,
  'requirements': instance.requirements,
  'participants': instance.participants,
  'teamIds': instance.teamIds,
  'courseId': instance.courseId,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt?.toIso8601String(),
  'metadata': instance.metadata,
};

const _$ChallengeTypeEnumMap = {
  ChallengeType.individual: 'individual',
  ChallengeType.team: 'team',
  ChallengeType.collaborative: 'collaborative',
  ChallengeType.coding: 'coding',
  ChallengeType.review: 'review',
  ChallengeType.learning: 'learning',
  ChallengeType.consistency: 'consistency',
};

const _$ChallengeStatusEnumMap = {
  ChallengeStatus.upcoming: 'upcoming',
  ChallengeStatus.active: 'active',
  ChallengeStatus.completed: 'completed',
  ChallengeStatus.cancelled: 'cancelled',
};
