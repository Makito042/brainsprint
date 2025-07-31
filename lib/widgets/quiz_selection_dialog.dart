import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../repositories/quiz_repository.dart';
import '../../models/quiz_model.dart';

/// A dialog that allows the user to select a quiz.
/// Returns the selected Quiz when the user taps the SELECT button.
class QuizSelectionDialog extends StatefulWidget {
  const QuizSelectionDialog({super.key});

  static Future<Quiz?> show(BuildContext context) async {
    return await showDialog<Quiz?>(
      context: context,
      builder: (context) => const QuizSelectionDialog(),
    );
  }

  @override
  State<QuizSelectionDialog> createState() => _QuizSelectionDialogState();
}

class _QuizSelectionDialogState extends State<QuizSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Quiz? _selectedQuiz;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizRepository = Provider.of<QuizRepository>(context);

    return AlertDialog(
      title: const Text('Select a Quiz'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Search quizzes',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<List<Quiz>>(
              stream: quizRepository.searchQuizzes(_searchQuery),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final quizzes = snapshot.data ?? [];

                if (quizzes.isEmpty) {
                  return Center(
                    child: _searchQuery.isEmpty
                        ? const Text('No quizzes available')
                        : const Text('No matching quizzes found'),
                  );
                }

                return ListView.builder(
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index];
                    return ListTile(
                      title: Text(quiz.title),
                      subtitle: Text(
                        quiz.description.isNotEmpty 
                            ? quiz.description 
                            : 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: _selectedQuiz?.id == quiz.id
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                      onTap: () {
                        setState(() {
                          _selectedQuiz = quiz;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _selectedQuiz == null 
              ? null 
              : () => Navigator.of(context).pop(_selectedQuiz),
          child: const Text('SELECT'),
        ),
      ],
    );
  }
}

// Helper function to show the quiz selection dialog
Future<Quiz?> showQuizSelectionDialog(BuildContext context) {
  return QuizSelectionDialog.show(context);
}
