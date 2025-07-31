import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/gamification_service.dart';
import '../models/gamification/achievement_model.dart';
import '../models/gamification/leaderboard_model.dart';
import '../models/gamification/challenge_model.dart';
import '../models/user_model.dart';

class GamificationProvider with ChangeNotifier {
  final GamificationService _gamificationService;
  
  // State
  List<UserAchievement> _achievements = [];
  List<Leaderboard> _leaderboards = [];
  List<Challenge> _challenges = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<UserAchievement> get achievements => _achievements;
  List<Leaderboard> get leaderboards => _leaderboards;
  List<Challenge> get challenges => _challenges;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _gamificationService.currentUserId;
  int get totalPoints => _achievements
      .where((a) => a.isUnlocked)
      .fold(0, (sum, a) => sum + a.points);

  // Constructor
  GamificationProvider({GamificationService? gamificationService})
      : _gamificationService = gamificationService ?? GamificationService() {
    _init();
  }
  
  // Update the service (used by ChangeNotifierProxyProvider)
  void updateService(GamificationService service) {
    // Only update if the service instance is different
    if (service != _gamificationService) {
      // Cancel any existing listeners if needed
      // _cancelSubscriptions();
      
      // Create a new GamificationProvider with the updated service
      final newProvider = GamificationProvider(gamificationService: service);
      
      // Update the internal state
      _achievements = newProvider._achievements;
      _leaderboards = newProvider._leaderboards;
      _challenges = newProvider._challenges;
      _isLoading = newProvider._isLoading;
      _error = newProvider._error;
      
      // Notify listeners about the change
      notifyListeners();
    }
  }

  // Initialize streams
  void _init() {
    _loadUserData();
  }

  // Load all user data
  Future<void> _loadUserData() async {
    final userId = _gamificationService.currentUserId;
    if (userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Set up achievement stream
      _gamificationService.getUserAchievements().listen((achievements) {
        _achievements = achievements;
        notifyListeners();
      });

      // Set up leaderboard stream
      _gamificationService.getActiveLeaderboards().listen((leaderboards) {
        _leaderboards = leaderboards;
        notifyListeners();
      });

      // Set up challenges stream
      _gamificationService.getUserChallenges().listen((challenges) {
        _challenges = challenges;
        notifyListeners();
      });
    } catch (e) {
      _error = 'Failed to load gamification data: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Track user activities
  Future<void> trackActivity({
    required String activityType,
    int value = 1,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _gamificationService.trackActivity(
        activityType: activityType,
        value: value,
        metadata: metadata,
      );
    } catch (e) {
      _error = 'Failed to track activity: $e';
      debugPrint(_error);
      notifyListeners();
    }
  }

  // Join a challenge
  Future<bool> joinChallenge(String challengeId) async {
    try {
      await _gamificationService.joinChallenge(challengeId);
      return true;
    } catch (e) {
      _error = 'Failed to join challenge: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  // Leave a challenge
  Future<bool> leaveChallenge(String challengeId) async {
    try {
      await _gamificationService.leaveChallenge(challengeId);
      return true;
    } catch (e) {
      _error = 'Failed to leave challenge: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  /// Creates a new challenge
  /// Returns the ID of the created challenge, or null if creation failed
  Future<String?> createChallenge({
    required String title,
    required String description,
    required ChallengeType type,
    required DateTime startDate,
    required DateTime endDate,
    int rewardPoints = 100,
    Map<String, dynamic>? metadata,
    List<String>? participants,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final challengeId = await _gamificationService.createChallenge(
        title: title,
        description: description,
        type: type,
        startDate: startDate,
        endDate: endDate,
        rewardPoints: rewardPoints,
        metadata: metadata,
        participants: participants,
      );

      return challengeId;
    } catch (e) {
      _error = 'Failed to create challenge: $e';
      debugPrint(_error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Search for users by name or email
  Future<List<AppUser>> searchUsers(String query) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final results = await _gamificationService.searchUsers(query);
      return results;
    } catch (e) {
      _error = 'Failed to search users: $e';
      debugPrint(_error);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get user's rank in a leaderboard
  int? getUserRank(String leaderboardId, String userId) {
    try {
      // First try to find the leaderboard
      final leaderboard = _leaderboards.firstWhere(
        (lb) => lb.leaderboardId == leaderboardId,
        orElse: () => Leaderboard(
          leaderboardId: leaderboardId,
          type: LeaderboardType.allTime, // Default type if not found
          startDate: DateTime.now(),
          entries: [],
        ),
      );

      // Then try to find the user's entry
      final entry = leaderboard.entries.firstWhere(
        (e) => e.userId == userId,
        orElse: () => LeaderboardEntry(
          userId: userId,
          username: 'You',
          score: 0,
          rank: 0,
        ),
      );
      
      // Return the rank, or 0 if not found
      return entry.rank > 0 ? entry.rank : null;
    } catch (e) {
      debugPrint('Error getting user rank: $e');
      return null;
    }
  }

  // Get user's achievements by type
  List<UserAchievement> getAchievementsByType(AchievementType type) {
    return _achievements.where((a) => a.type == type).toList();
  }

  // Get active challenges
  List<Challenge> get activeChallenges => _challenges
      .where((c) => c.status == ChallengeStatus.active)
      .toList();

  // Get upcoming challenges
  List<Challenge> get upcomingChallenges => _challenges
      .where((c) => c.status == ChallengeStatus.upcoming)
      .toList();

  // Get completed challenges
  List<Challenge> get completedChallenges => _challenges
      .where((c) => c.status == ChallengeStatus.completed)
      .toList();

  // Format points for display
  String formatPoints(int points) {
    return _gamificationService.formatPoints(points);
  }

  // Get achievement progress percentage
  double getAchievementProgress(UserAchievement achievement) {
    return _gamificationService.getAchievementProgress(achievement);
  }

  // Get time remaining for a challenge
  String getTimeRemaining(Challenge challenge) {
    return _gamificationService.getTimeRemaining(challenge);
  }

  // Check if a challenge is joinable
  bool isChallengeJoinable(Challenge challenge) {
    return _gamificationService.isChallengeJoinable(challenge);
  }

  // Refresh all data
  Future<void> refresh() async {
    _loadUserData();
  }
}
