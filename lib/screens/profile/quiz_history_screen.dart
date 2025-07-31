import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../models/course_model.dart';
import 'package:intl/intl.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({super.key});

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  Future<Course?> _getCourse(String courseId) async {
    try {
      if (courseId.isEmpty) return null;
      
      final doc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(courseId)
          .get();
          
      if (doc.exists) {
        return Course.fromMap(doc.data() ?? {}, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching course: $e');
      return null;
    }
  }
  
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is int) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return '';
    }
    
    return DateFormat('MMM d, y • hh:mm a').format(date);
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final userId = auth.FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      debugPrint('No user ID found - user not signed in');
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your quiz history')),
      );
    }
    
    debugPrint('Loading quiz history for user: $userId');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('quiz_attempts')
            .orderBy('timestamp', descending: true)
            .snapshots()
            .handleError((error) {
              debugPrint('❌ Error fetching quiz attempts: $error');
            })
            .map((snapshot) {
              debugPrint('📊 Got ${snapshot.docs.length} quiz attempts');
              if (snapshot.docs.isNotEmpty) {
                debugPrint('📄 First document data: ${snapshot.docs.first.data()}');
              }
              return snapshot;
            }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('❌ Error in snapshot: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData) {
            debugPrint('ℹ️ No data received from server yet');
            return const Center(child: Text('No data received from server'));
          }
          
          if (snapshot.data!.docs.isEmpty) {
            debugPrint('No quiz attempts found for user: $userId');
            return const Center(child: Text('No quiz attempts found'));
          }

          final attempts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: attempts.length,
            itemBuilder: (context, index) {
              final doc = attempts[index];
              debugPrint('Document ID: ${doc.id}');
              debugPrint('Document data: ${doc.data()}');
              
              final attempt = doc.data() as Map<String, dynamic>;
              final quizTitle = attempt['quizTitle'] ?? 'Unknown Quiz';
              final score = attempt['score']?.toString() ?? '0';
              final totalQuestions = attempt['totalQuestions']?.toString() ?? '?';
              final percentage = (attempt['percentage'] as num?)?.toDouble() ?? 0.0;
              final timestamp = (attempt['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quizTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Score: $score/$totalQuestions • ${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _formatDate(attempt['timestamp']),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getScoreColor(percentage).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: _getScoreColor(percentage),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  onTap: () {
                    // TODO: Navigate to detailed quiz results if needed
                  }
                ),
              );
            },
          );
        },
      ),
    );
  }


}
