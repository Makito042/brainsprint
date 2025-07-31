import 'package:cloud_firestore/cloud_firestore.dart';

enum ChallengeType {
  individual,
  team,
  collaborative,
  coding,
  review,
  learning,
  consistency,
  quiz, // For one-on-one quiz challenges between users
}

enum ChallengeStatus {
  upcoming,
  active,
  completed,
  cancelled,
}

class Challenge {
  final String challengeId;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final int rewardPoints;
  final Map<String, dynamic> requirements;
  final List<String> participants;
  final List<String>? teamIds;
  final String? courseId;
  final String? createdBy;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  // Factory method for creating quiz challenges
  static Challenge createQuizChallenge({
    required String title,
    required String description,
    required String quizId,
    required String quizTitle,
    required String challengerId,
    required String challengedUserId,
    required DateTime endDate,
    int rewardPoints = 100, // Default reward points for quiz challenges
  }) {
    final now = DateTime.now();
    return Challenge(
      challengeId: '', // Will be set by Firestore
      title: title,
      description: description,
      type: ChallengeType.quiz,
      status: ChallengeStatus.upcoming,
      startDate: now,
      endDate: endDate,
      rewardPoints: rewardPoints,
      requirements: {},
      participants: [challengerId, challengedUserId],
      createdBy: challengerId,
      metadata: {
        'quizId': quizId,
        'quizTitle': quizTitle,
        'challengerId': challengerId,
        'challengedUserId': challengedUserId,
        'challengerScore': null, // Will be set when the quiz is taken
        'challengedUserScore': null, // Will be set when the quiz is taken
        'challengerCompleted': false,
        'challengedUserCompleted': false,
      },
    );
  }

  Challenge({
    required this.challengeId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.rewardPoints,
    required this.requirements,
    required this.participants,
    this.teamIds,
    this.courseId,
    this.createdBy,
    this.createdAt,
    this.metadata,
  });

  // Convert Firestore DocumentSnapshot to Challenge
  factory Challenge.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return Challenge(
      challengeId: snapshot.id,
      title: data['title'] as String,
      description: data['description'] as String,
      type: ChallengeType.values.firstWhere(
        (e) => e.toString() == 'ChallengeType.${data['type']}',
        orElse: () => ChallengeType.individual,
      ),
      status: ChallengeStatus.values.firstWhere(
        (e) => e.toString() == 'ChallengeStatus.${data['status']}',
        orElse: () => ChallengeStatus.upcoming,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      rewardPoints: data['rewardPoints'] as int,
      requirements: data['requirements'] as Map<String, dynamic>,
      participants: List<String>.from(data['participants'] as List<dynamic>),
      teamIds: data['teamIds'] != null 
          ? List<String>.from(data['teamIds'] as List<dynamic>)
          : null,
      courseId: data['courseId'] as String?,
      createdBy: data['createdBy'] as String?,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  // Helper methods for quiz challenges
  bool get isQuizChallenge => type == ChallengeType.quiz;
  
  String? get quizId => isQuizChallenge && metadata != null ? metadata!['quizId'] as String? : null;
  String? get quizTitle => isQuizChallenge && metadata != null ? metadata!['quizTitle'] as String? : null;
  String? get challengedUserId => isQuizChallenge && metadata != null ? metadata!['challengedUserId'] as String? : null;
  int? get challengerScore => isQuizChallenge && metadata != null ? metadata!['challengerScore'] as int? : null;
  int? get challengedUserScore => isQuizChallenge && metadata != null ? metadata!['challengedUserScore'] as int? : null;
  bool get isChallengerCompleted => isQuizChallenge && metadata != null ? metadata!['challengerCompleted'] as bool? ?? false : false;
  bool get isChallengedUserCompleted => isQuizChallenge && metadata != null ? metadata!['challengedUserCompleted'] as bool? ?? false : false;
  bool get isQuizCompleted => isChallengerCompleted && isChallengedUserCompleted;
  
  // Get the winner of the quiz challenge (returns userId or null if draw)
  String? get quizWinner {
    if (!isQuizCompleted) return null;
    if (challengerScore == null || challengedUserScore == null) return null;
    
    if (challengerScore! > challengedUserScore!) return participants[0];
    if (challengedUserScore! > challengerScore!) return participants[1];
    return null; // It's a draw
  }
  
  // Check if a user is the winner of this quiz challenge
  bool isWinner(String userId) => quizWinner == userId;
  
  // Check if the quiz challenge resulted in a draw
  bool get isDraw => isQuizCompleted && quizWinner == null;
  
  // Convert Challenge to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'rewardPoints': rewardPoints,
      'requirements': requirements,
      'participants': participants,
      if (teamIds != null) 'teamIds': teamIds,
      if (courseId != null) 'courseId': courseId,
      if (createdBy != null) 'createdBy': createdBy,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (metadata != null) 'metadata': metadata,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }


  Challenge copyWith({
    String? title,
    String? description,
    ChallengeType? type,
    ChallengeStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? rewardPoints,
    Map<String, dynamic>? requirements,
    List<String>? participants,
    List<String>? teamIds,
    String? courseId,
    Map<String, dynamic>? metadata,
  }) {
    return Challenge(
      challengeId: challengeId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      requirements: requirements ?? this.requirements,
      participants: participants ?? this.participants,
      teamIds: teamIds ?? this.teamIds,
      courseId: courseId ?? this.courseId,
      createdBy: createdBy,
      createdAt: createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isActive =>
      status == ChallengeStatus.active &&
      DateTime.now().isAfter(startDate) &&
      DateTime.now().isBefore(endDate);

  bool get isUpcoming =>
      status == ChallengeStatus.upcoming && DateTime.now().isBefore(startDate);

  bool get isCompleted => status == ChallengeStatus.completed || 
      (status == ChallengeStatus.active && DateTime.now().isAfter(endDate));
}
