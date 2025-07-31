import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class FirestoreDebugScreen extends StatefulWidget {
  const FirestoreDebugScreen({super.key});

  @override
  _FirestoreDebugScreenState createState() => _FirestoreDebugScreenState();
}

class _FirestoreDebugScreenState extends State<FirestoreDebugScreen> {
  final _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _quizAttempts = [];
  bool _isLoading = true;
  String _error = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadQuizAttempts();
  }

  Future<void> _loadQuizAttempts() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final user = auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      _userId = user.uid;
      debugPrint('🔍 Loading quiz attempts for user: $_userId');

      // Read from user's quiz_attempts subcollection
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('quiz_attempts')
          .orderBy('timestamp', descending: true)
          .get();

      debugPrint('📊 Found ${querySnapshot.docs.length} quiz attempts');
      
      final attempts = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        debugPrint('📝 Attempt data: $data');
        return data;
      }).toList();

      setState(() {
        _quizAttempts = attempts.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading quiz attempts: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQuizAttempts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : _buildQuizAttemptsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadQuizAttempts,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildQuizAttemptsList() {
    if (_quizAttempts.isEmpty) {
      return const Center(child: Text('No quiz attempts found'));
    }

    return ListView.builder(
      itemCount: _quizAttempts.length,
      itemBuilder: (context, index) {
        final attempt = _quizAttempts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text('${attempt['courseName']} - ${attempt['quizName']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Score: ${attempt['score']}/${attempt['totalQuestions']} (${(attempt['percentage'] as num).toStringAsFixed(1)}%)'),
                Text('Date: ${DateTime.fromMillisecondsSinceEpoch(attempt['timestamp']).toString()}'),
                Text('User ID: ${attempt['userId']}'),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
