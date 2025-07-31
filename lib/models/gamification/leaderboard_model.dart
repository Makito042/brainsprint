import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'leaderboard_model.g.dart';

enum LeaderboardType {
  daily,
  weekly,
  monthly,
  allTime,
  course,
  team,
}

@JsonSerializable()
class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int score;
  final int rank;
  final Map<String, dynamic>? metadata;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.score,
    required this.rank,
    this.metadata,
  });

  // Convert Firestore data to LeaderboardEntry
  factory LeaderboardEntry.fromFirestore(Map<String, dynamic> data) {
    return LeaderboardEntry(
      userId: data['userId'] as String,
      username: data['username'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      score: data['score'] as int,
      rank: data['rank'] as int? ?? 0,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert LeaderboardEntry to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'score': score,
      'rank': rank,
      if (metadata != null) 'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // JSON serialization (kept for compatibility)
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      score: json['score'] as int,
      rank: json['rank'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'avatarUrl': avatarUrl,
      'score': score,
      'rank': rank,
      'metadata': metadata,
    };
  }

  // Create a copy of this LeaderboardEntry with the given fields replaced with the new values
  LeaderboardEntry copyWith({
    String? userId,
    String? username,
    String? avatarUrl,
    int? score,
    int? rank,
    Map<String, dynamic>? metadata,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class Leaderboard {
  final String leaderboardId;
  final LeaderboardType type;
  final String? courseId;
  final DateTime startDate;
  final DateTime? endDate;
  final List<LeaderboardEntry> entries;
  final Map<String, dynamic>? metadata;

  Leaderboard({
    required this.leaderboardId,
    required this.type,
    this.courseId,
    required this.startDate,
    this.endDate,
    required this.entries,
    this.metadata,
  });

  // Convert Firestore DocumentSnapshot to Leaderboard
  factory Leaderboard.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Leaderboard(
      leaderboardId: snapshot.id,
      type: LeaderboardType.values.firstWhere(
        (e) => e.toString() == 'LeaderboardType.${data['type']}',
        orElse: () => LeaderboardType.allTime,
      ),
      courseId: data['courseId'] as String?,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate() 
          : null,
      entries: (data['entries'] as List<dynamic>? ?? [])
          .map((e) => LeaderboardEntry.fromFirestore(e as Map<String, dynamic>))
          .toList(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert Leaderboard to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.toString().split('.').last,
      if (courseId != null) 'courseId': courseId,
      'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'entries': entries.map((e) => e.toFirestore()).toList(),
      if (metadata != null) 'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // JSON serialization (kept for compatibility)
  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      leaderboardId: json['leaderboardId'] as String,
      type: LeaderboardType.values.firstWhere(
        (e) => e.toString() == 'LeaderboardType.${json['type']}',
        orElse: () => LeaderboardType.allTime,
      ),
      courseId: json['courseId'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String) 
          : null,
      entries: (json['entries'] as List<dynamic>)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leaderboardId': leaderboardId,
      'type': type.toString().split('.').last,
      'courseId': courseId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
      'metadata': metadata,
    };
  }

}
