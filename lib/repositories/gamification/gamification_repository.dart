import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/gamification/achievement_model.dart';
import '../../models/gamification/leaderboard_model.dart';
import '../../models/gamification/challenge_model.dart';

class GamificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GamificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Collection references
  CollectionReference<UserAchievement> get _userAchievementsRef => _firestore
      .collection('gamification')
      .doc('userAchievements')
      .collection('items')
      .withConverter<UserAchievement>(
        fromFirestore: (snapshot, options) =>
            UserAchievement.fromFirestore(snapshot, options),
        toFirestore: (achievement, _) => achievement.toFirestore(),
      );

  CollectionReference<Leaderboard> get _leaderboardsRef => _firestore
      .collection('gamification')
      .doc('leaderboards')
      .collection('items')
      .withConverter<Leaderboard>(
        fromFirestore: (snapshot, options) =>
            Leaderboard.fromFirestore(snapshot, options),
        toFirestore: (leaderboard, _) => leaderboard.toFirestore(),
      );

  CollectionReference<Challenge> get _challengesRef => _firestore
      .collection('gamification')
      .doc('challenges')
      .collection('items')
      .withConverter<Challenge>(
        fromFirestore: (snapshot, options) =>
            Challenge.fromFirestore(snapshot, options),
        toFirestore: (challenge, _) => challenge.toFirestore(),
      );

  // Achievement methods
  Stream<List<UserAchievement>> getUserAchievements(String userId) {
    return _userAchievementsRef
        .where('userId', isEqualTo: userId)
        .orderBy('achievedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<UserAchievement?> getAchievement(String achievementId) async {
    final doc = await _userAchievementsRef.doc(achievementId).get();
    return doc.data();
  }

  Future<void> addUserAchievement(UserAchievement achievement) async {
    await _userAchievementsRef.doc(achievement.achievementId).set(achievement);
  }

  Future<void> updateAchievementProgress({
    required String achievementId,
    required String userId,
    double? progress,
    bool? isUnlocked,
  }) async {
    final docRef = _userAchievementsRef.doc(achievementId);
    
    if ((await docRef.get()).exists) {
      // Update existing achievement
      final updateData = <String, dynamic>{
        if (progress != null) 'progress': progress,
        if (isUnlocked != null) 'isUnlocked': isUnlocked,
        if (isUnlocked == true) 'achievedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await docRef.update(updateData);
    } else {
      // Create new achievement if it doesn't exist
      final achievement = UserAchievement(
        achievementId: achievementId,
        userId: userId,
        type: AchievementType.badge, // Default type, can be updated later
        title: 'New Achievement',
        description: 'Complete tasks to unlock',
        icon: 'assets/icons/trophy.png',
        points: 0,
        achievedAt: DateTime.now(),
        progress: progress ?? 0.0,
        isUnlocked: isUnlocked ?? false,
      );
      await addUserAchievement(achievement);
    }
  }

  Future<void> unlockAchievement(String achievementId, String userId) async {
    await updateAchievementProgress(
      achievementId: achievementId,
      userId: userId,
      isUnlocked: true,
      progress: 1.0,
    );
  }

  // Leaderboard methods
  Stream<Leaderboard?> getLeaderboard(String leaderboardId) {
    return _leaderboardsRef
        .doc(leaderboardId)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  Future<Leaderboard?> getLeaderboardOnce(String leaderboardId) async {
    final doc = await _leaderboardsRef.doc(leaderboardId).get();
    return doc.data();
  }

  Stream<List<Leaderboard>> getActiveLeaderboards({
    LeaderboardType? type,
    String? courseId,
  }) {
    final now = DateTime.now();
    var query = _leaderboardsRef
        .where('startDate', isLessThanOrEqualTo: now)
        .where('endDate', isGreaterThan: now);

    if (type != null) {
      query = query.where('type', isEqualTo: type.toString().split('.').last);
    }

    if (courseId != null) {
      query = query.where('courseId', isEqualTo: courseId);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<String> createLeaderboard({
    required LeaderboardType type,
    required String title,
    String? description,
    String? courseId,
    DateTime? startDate,
    DateTime? endDate,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();
    final leaderboard = Leaderboard(
      leaderboardId: _leaderboardsRef.doc().id,
      type: type,
      courseId: courseId,
      startDate: startDate ?? now,
      endDate: endDate ?? now.add(const Duration(days: 7)),
      entries: [],
      metadata: metadata ?? {},
    );

    await _leaderboardsRef.doc(leaderboard.leaderboardId).set(leaderboard);
    return leaderboard.leaderboardId;
  }

  Future<void> updateLeaderboardEntry(
    String leaderboardId, 
    LeaderboardEntry entry,
  ) async {
    final docRef = _leaderboardsRef.doc(leaderboardId);
    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);
      if (!doc.exists) {
        throw Exception('Leaderboard not found');
      }

      final leaderboard = doc.data()!;
      final entries = List<LeaderboardEntry>.from(leaderboard.entries);
      final existingIndex = entries.indexWhere((e) => e.userId == entry.userId);

      if (existingIndex >= 0) {
        entries[existingIndex] = entry;
      } else {
        entries.add(entry);
      }

      // Sort by score desc
      entries.sort((a, b) => b.score.compareTo(a.score));
      
      // Update ranks
      final rankedEntries = entries.asMap().map((index, e) => MapEntry(
            index,
            e.copyWith(rank: index + 1),
          ));

      transaction.update(docRef, {'entries': rankedEntries.values.toList()});
    });
  }

  // Challenge methods
  Stream<List<Challenge>> getChallengesForUser(String userId) {
    return _challengesRef
        .where('participants', arrayContains: userId)
        .orderBy('startDate')
        .withConverter<Challenge>(
          fromFirestore: (doc, _) => Challenge.fromFirestore(doc, null),
          toFirestore: (challenge, _) => challenge.toFirestore(),
        )
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> joinChallenge(String challengeId, String userId) async {
    await _challengesRef.doc(challengeId).update({
      'participants': FieldValue.arrayUnion([userId]),
    });
  }

  /// Creates a new challenge in Firestore
  /// Returns the ID of the newly created challenge
  Future<String> createChallenge(Challenge challenge) async {
    final docRef = _challengesRef.doc().withConverter<Challenge>(
          fromFirestore: (doc, _) => Challenge.fromFirestore(doc, null),
          toFirestore: (challenge, _) => challenge.toFirestore(),
        );
    
    // Create a new Challenge instance with the generated document ID
    final challengeWithId = Challenge(
      challengeId: docRef.id,
      title: challenge.title,
      description: challenge.description,
      type: challenge.type,
      status: challenge.status,
      startDate: challenge.startDate,
      endDate: challenge.endDate,
      rewardPoints: challenge.rewardPoints,
      requirements: challenge.requirements,
      participants: challenge.participants,
      teamIds: challenge.teamIds,
      courseId: challenge.courseId,
      createdBy: challenge.createdBy,
      createdAt: DateTime.now(),
      metadata: challenge.metadata,
    );
    
    await docRef.set(challengeWithId);
    return docRef.id;
  }

  Future<void> leaveChallenge(String challengeId, String userId) async {
    await _challengesRef.doc(challengeId).update({
      'participants': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> updateChallengeStatus(
    String challengeId, 
    ChallengeStatus status,
  ) async {
    await _challengesRef.doc(challengeId).update({
      'status': status.toString().split('.').last,
    });
  }

  // Helper method to track user activity that might trigger achievements
  Future<void> trackUserActivity({
    required String userId,
    required String activityType,
    int value = 1,
    Map<String, dynamic>? metadata,
  }) async {
    // This would be expanded to check for various achievement triggers
    // based on activity type and update user progress accordingly
    
    // Example: Track daily login streak
    if (activityType == 'daily_login') {
      await _updateStreakAchievement(userId, 'daily_login_streak', value);
    }
    
    // Add more activity type handlers as needed
  }

  Future<void> _updateStreakAchievement(
    String userId, 
    String achievementKey, 
    int increment,
  ) async {
    final achievementRef = _userAchievementsRef
        .where('userId', isEqualTo: userId)
        .where('metadata.achievementKey', isEqualTo: achievementKey);

    final snapshot = await achievementRef.get();
    final now = DateTime.now();

    if (snapshot.docs.isEmpty) {
      // Create new streak
      final achievement = UserAchievement(
        achievementId: '${userId}_$achievementKey',
        userId: userId,
        type: AchievementType.streak,
        title: '$increment Day Streak!',
        description: 'Logged in for $increment days in a row',
        icon: '🔥',
        points: 10 * increment,
        achievedAt: now,
        progress: increment.toDouble(),
        targetValue: 7, // 7-day streak target
        isUnlocked: increment >= 7,
        metadata: {
          'achievementKey': achievementKey,
          'lastUpdated': now.toIso8601String(),
        },
      );
      await addUserAchievement(achievement);
    } else {
      // Update existing streak
      final doc = snapshot.docs.first;
      final achievement = doc.data();
      final lastUpdated = DateTime.parse(achievement.metadata?['lastUpdated'] ?? now.toIso8601String());
      final isNewDay = now.difference(lastUpdated).inHours >= 24;

      if (isNewDay) {
        final newCount = (achievement.progress + increment).toInt();
        final isUnlocked = newCount >= (achievement.targetValue as int);
        
        await doc.reference.update({
          'title': '$newCount Day Streak!',
          'description': 'Logged in for $newCount days in a row',
          'points': 10 * newCount,
          'progress': newCount.toDouble(),
          'isUnlocked': isUnlocked,
          'metadata.lastUpdated': now.toIso8601String(),
          if (isUnlocked) 'achievedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}
