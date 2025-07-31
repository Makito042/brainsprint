import 'package:firebase_auth/firebase_auth.dart' as auth;

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? phoneNumber;
  final int quizzesTaken;
  final double highestScore;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.phoneNumber,
    this.quizzesTaken = 0,
    this.highestScore = 0.0,
  });

  factory AppUser.fromFirebaseUser(auth.User user, [Map<String, dynamic>? userData]) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
      phoneNumber: user.phoneNumber,
      quizzesTaken: userData?['quizzesTaken'] ?? 0,
      highestScore: (userData?['highestScore'] ?? 0).toDouble(),
    );
  }

  // Convert to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'phoneNumber': phoneNumber,
      'quizzesTaken': quizzesTaken,
      'highestScore': highestScore,
    };
  }
  
  // Create a copy with updated fields
  AppUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    int? quizzesTaken,
    double? highestScore,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      quizzesTaken: quizzesTaken ?? this.quizzesTaken,
      highestScore: highestScore ?? this.highestScore,
    );
  }
}
