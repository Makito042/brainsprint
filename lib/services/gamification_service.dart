import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../repositories/user_repository.dart';
import '../models/gamification/achievement_model.dart';
import '../models/gamification/leaderboard_model.dart';
import '../models/gamification/challenge_model.dart';
import '../models/user_model.dart';
import '../repositories/gamification/gamification_repository.dart';
import '../repositories/user_repository.dart';

class GamificationService {
  final GamificationRepository _repository;
  final FirebaseAuth _auth;
  final UserRepository _userRepository;

  GamificationService({
    GamificationRepository? repository,
    FirebaseAuth? auth,
    UserRepository? userRepository,
  })  : _repository = repository ?? GamificationRepository(),
        _auth = auth ?? FirebaseAuth.instance,
        _userRepository = userRepository ?? UserRepository();

  // Getters for current user data
  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;

  // Achievement methods
  Stream<List<UserAchievement>> getUserAchievements() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _repository.getUserAchievements(userId);
  }

  // Leaderboard methods
  Stream<Leaderboard?> getLeaderboard(String leaderboardId) {
    return _repository.getLeaderboard(leaderboardId);
  }

  Stream<List<Leaderboard>> getActiveLeaderboards({
    LeaderboardType? type,
    String? courseId,
  }) {
    return _repository.getActiveLeaderboards(
      type: type,
      courseId: courseId,
    );
  }

  // Challenge methods
  Stream<List<Challenge>> getUserChallenges() {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _repository.getChallengesForUser(userId);
  }

  Future<void> joinChallenge(String challengeId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    await _repository.joinChallenge(challengeId, userId);
  }

  Future<void> leaveChallenge(String challengeId) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    await _repository.leaveChallenge(challengeId, userId);
  }

  // Activity tracking
  Future<void> trackActivity({
    required String activityType,
    int value = 1,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _repository.trackUserActivity(
      userId: userId,
      activityType: activityType,
      value: value,
      metadata: metadata,
    );
  }

  // Specific activity tracking methods
  Future<void> trackDailyLogin() async {
    await trackActivity(activityType: 'daily_login');
  }

  Future<void> trackQuizCompleted({
    required String quizId,
    required int score,
    required int maxScore,
    required String courseId,
    required String courseName,
    required BuildContext context,
  }) async {
    // Track the quiz completion as an activity
    await trackActivity(
      activityType: 'quiz_completed',
      value: 1,
      metadata: {
        'quizId': quizId,
        'score': score,
        'maxScore': maxScore,
        'courseId': courseId,
      },
    );

    final percentageScore = (score / maxScore) * 100;

    final userRepo = Provider.of<UserRepository>(
      context,
      listen: false,
    );
    await userRepo.updateHighestScore(percentageScore);
  }

  Future<void> trackContentViewed({
    required String contentId,
    required String contentType,
    required String courseId,
    int durationSeconds = 0,
  }) async {
    await trackActivity(
      activityType: 'content_viewed',
      value: durationSeconds,
      metadata: {
        'contentId': contentId,
        'contentType': contentType,
        'courseId': courseId,
        'durationSeconds': durationSeconds,
      },
    );
  }

  // Helper methods for UI
  String formatPoints(int points) {
    if (points >= 1000000) {
      return '${(points / 1000000).toStringAsFixed(1)}M';
    } else if (points >= 1000) {
      return '${(points / 1000).toStringAsFixed(1)}K';
    }
    return points.toString();
  }

  // Get achievement progress as a percentage (0-100)
  double getAchievementProgress(UserAchievement achievement) {
    if (achievement.isUnlocked) return 100.0;
    if (achievement.targetValue == null) return 0.0;
    
    final progress = (achievement.progress / achievement.targetValue) * 100;
    return progress > 100 ? 100.0 : progress;
  }

  // Get time remaining for a challenge
  String getTimeRemaining(Challenge challenge) {
    final now = DateTime.now();
    if (now.isAfter(challenge.endDate)) return 'Ended';
    
    final remaining = challenge.endDate.difference(now);
    
    if (remaining.inDays > 0) {
      return '${remaining.inDays}d ${remaining.inHours % 24}h left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m left';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes}m left';
    } else {
      return 'Ending soon';
    }
  }

  // Check if a challenge is joinable
  bool isChallengeJoinable(Challenge challenge) {
    final now = DateTime.now();
    return challenge.status == ChallengeStatus.active &&
        now.isAfter(challenge.startDate) &&
        now.isBefore(challenge.endDate);
  }

  /// Search for users by name or email
  /// Returns a list of users matching the query (excluding the current user)
  Future<List<AppUser>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return [];
      }
      return await _userRepository.searchUsers(query);
    } catch (e) {
      debugPrint('Error searching users: $e');
      rethrow;
    }
  }

  /// Creates a new challenge
  /// Returns the ID of the newly created challenge
  Future<String> createChallenge({
    required String title,
    required String description,
    required ChallengeType type,
    required DateTime startDate,
    required DateTime endDate,
    int rewardPoints = 100,
    Map<String, dynamic>? metadata,
    List<String>? participants,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Create the challenge
    final challenge = Challenge(
      challengeId: '', // Will be set by the repository
      title: title,
      description: description,
      type: type,
      status: ChallengeStatus.upcoming,
      startDate: startDate,
      endDate: endDate,
      rewardPoints: rewardPoints,
      requirements: const {},
      participants: participants ?? [userId],
      createdBy: userId,
      metadata: metadata ?? {},
    );

    try {
      // Save to Firestore
      return await _repository.createChallenge(challenge);
    } catch (e) {
      debugPrint('Error creating challenge: $e');
      rethrow;
    }
  }
}
