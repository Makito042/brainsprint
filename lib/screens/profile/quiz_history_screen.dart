import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../models/course_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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

  Future<void> _deleteQuizAttempt(String attemptId) async {
    final userId = auth.FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quiz Attempt'),
        content: const Text('Are you sure you want to delete this quiz attempt? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('quiz_attempts')
            .doc(attemptId)
            .delete();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz attempt deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete quiz attempt')),
          );
        }
        debugPrint('Error deleting quiz attempt: $e');
      }
    }
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
          
          if (snapshot.data!.docs.isEmpty || 
              (snapshot.data!.docs.length == 1 && 
               snapshot.data!.docs.first.id == '_init')) {
            debugPrint('No quiz attempts found for user: $userId');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Quiz History Yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete a quiz to see your attempt history here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to quiz selection
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/home', 
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.quiz),
                      label: const Text('Take a Quiz'),
                    ),
                  ],
                ),
              ),
            );
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

              return Slidable(
                key: Key(doc.id),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) => _deleteQuizAttempt(doc.id),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: 'Delete',
                    ),
                  ],
                ),
                child: Card(
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
                  },
                ),
              ),
            );
            },
          );
        },
      ),
    );
  }
}
