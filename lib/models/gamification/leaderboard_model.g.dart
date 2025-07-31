// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaderboardEntry _$LeaderboardEntryFromJson(Map<String, dynamic> json) =>
    LeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      score: (json['score'] as num).toInt(),
      rank: (json['rank'] as num).toInt(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$LeaderboardEntryToJson(LeaderboardEntry instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
      'score': instance.score,
      'rank': instance.rank,
      'metadata': instance.metadata,
    };

Leaderboard _$LeaderboardFromJson(Map<String, dynamic> json) => Leaderboard(
  leaderboardId: json['leaderboardId'] as String,
  type: $enumDecode(_$LeaderboardTypeEnumMap, json['type']),
  courseId: json['courseId'] as String?,
  startDate: DateTime.parse(json['startDate'] as String),
  endDate: json['endDate'] == null
      ? null
      : DateTime.parse(json['endDate'] as String),
  entries: (json['entries'] as List<dynamic>)
      .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$LeaderboardToJson(Leaderboard instance) =>
    <String, dynamic>{
      'leaderboardId': instance.leaderboardId,
      'type': _$LeaderboardTypeEnumMap[instance.type]!,
      'courseId': instance.courseId,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'entries': instance.entries,
      'metadata': instance.metadata,
    };

const _$LeaderboardTypeEnumMap = {
  LeaderboardType.daily: 'daily',
  LeaderboardType.weekly: 'weekly',
  LeaderboardType.monthly: 'monthly',
  LeaderboardType.allTime: 'allTime',
  LeaderboardType.course: 'course',
  LeaderboardType.team: 'team',
};
