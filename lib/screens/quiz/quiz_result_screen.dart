import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/quiz_model.dart';
import '../../repositories/user_repository.dart';
import 'quiz_list_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final Quiz quiz;
  final Course course;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.quiz,
    required this.course,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  int _currentIndex = 0;
  final UserRepository _userRepository = UserRepository();
  bool _hasRecordedScore = false;

  @override
  void initState() {
    super.initState();
    _updateUserScore();
  }

  Future<void> _updateUserScore() async {
    if (_hasRecordedScore) return;
    
    try {
      final userId = _userRepository.currentUserId;
      if (userId == null) {
        debugPrint('No authenticated user');
        return;
      }
      
      final percentage = (widget.score / widget.totalQuestions) * 100;
      
      // Update user's highest score if needed
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
          
      if (userDoc.exists) {
        final currentHighScore = (userDoc.data()?['highestScore'] as num?)?.toDouble() ?? 0.0;
        if (percentage > currentHighScore) {
          await userDoc.reference.update({
            'highestScore': percentage,
          });
        }
      }

      // Save quiz attempt to user's quiz_attempts subcollection
      debugPrint('🔄 Saving quiz attempt to user\'s quiz_attempts subcollection...');
      debugPrint('📝 Course ID: ${widget.course.id}, Quiz ID: ${widget.quiz.id}, Score: ${widget.score}');
      
      final attemptData = {
        'courseId': widget.course.id,
        'courseName': widget.course.name,
        'quizId': widget.quiz.id,
        'quizTitle': widget.quiz.title,  // Changed from quizName to quizTitle to match query
        'score': widget.score,
        'totalQuestions': widget.totalQuestions,
        'percentage': percentage,
        'timestamp': FieldValue.serverTimestamp(),
      };
      
      debugPrint('Attempt data: $attemptData');
      
      try {
        final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
        final docRef = await userDocRef.collection('quiz_attempts').add(attemptData);
        debugPrint('✅ Quiz attempt saved to user\'s subcollection with ID: ${docRef.id}');
        debugPrint('📄 Document data: $attemptData');
        
        // Verify the document was saved
        final doc = await docRef.get();
        if (doc.exists) {
          debugPrint('🔍 Successfully retrieved saved attempt: ${doc.data()}');
        } else {
          debugPrint('❌ Failed to retrieve saved attempt');
        }
      } catch (error) {
        debugPrint('❌ Error saving quiz attempt to user subcollection: $error');
        rethrow; // Re-throw to be caught by the outer catch block
      }

      // Increment the quiz count
      await _userRepository.incrementQuizCount();
      
      setState(() {
        _hasRecordedScore = true;
      });
    } catch (e) {
      debugPrint('Error recording quiz attempt: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double percentage = (widget.score / widget.totalQuestions) * 100;
    
    return WillPopScope(
      onWillPop: () async {
        // Navigate back to the home screen
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Results'),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Navigate back to the quiz list screen with the same course
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizListScreen(course: widget.course),
                ),
              );
            },
          ),
        ),
        body: _buildBody(percentage),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              label: 'Results',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.question_answer_outlined),
              label: 'Answers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard_outlined),
              label: 'Leaderboard',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(double percentage) {
    switch (_currentIndex) {
      case 0:
        return _buildResultsTab(percentage);
      case 1:
        return _buildAnswersTab();
      case 2:
        return _buildLeaderboardTab();
      default:
        return _buildResultsTab(percentage);
    }
  }

  Widget _buildResultsTab(double percentage) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getScoreColor(percentage),
                width: 10,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getScoreMessage(percentage),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'You scored',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.score} out of ${widget.totalQuestions}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          _buildStatRow('Correct Answers', '${widget.score}'),
          _buildStatRow('Incorrect Answers', '${widget.totalQuestions - widget.score}'),
          _buildStatRow('Skipped', '0'),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // Navigate back to the quiz list screen with the same course
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizListScreen(course: widget.course),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white, // Ensure text is white
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2, // Add slight elevation for better visibility
              ),
              child: const Text(
                'Back to Quizzes',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white, // Explicitly set text color to white
                  fontWeight: FontWeight.w600, // Slightly bolder text
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.quiz.questions.length,
      itemBuilder: (context, index) {
        final question = widget.quiz.questions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${index + 1}: ${question.question}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Correct Answer:',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  question.options[question.correctIndex],
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explanation:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                Text(
                  question.explanation,
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Leaderboard Coming Soon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later to see how you rank!',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage(double percentage) {
    if (percentage >= 90) return 'Excellent!';
    if (percentage >= 70) return 'Good job!';
    if (percentage >= 50) return 'Not bad!';
    return 'Keep practicing!';
  }
}
