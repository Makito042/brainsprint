import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final Course course;

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.course,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _showExplanation = false;
  int? _selectedAnswerIndex;

  void _nextQuestion() {
    if (_selectedAnswerIndex != null) {
      if (_selectedAnswerIndex == widget.quiz.questions[_currentQuestionIndex].correctIndex) {
        _score++;
      }
      setState(() {
        _showExplanation = true;
      });
    }
  }

  void _nextQuestionAfterExplanation() {
    if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _showExplanation = false;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: '/quiz-result'),
          builder: (context) => QuizResultScreen(
            score: _score,
            totalQuestions: widget.quiz.questions.length,
            quiz: widget.quiz,
            course: widget.course,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
            Text(
              'Question ${_currentQuestionIndex + 1} of ${widget.quiz.questions.length}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.quiz.questions[_currentQuestionIndex].question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ...widget.quiz.questions[_currentQuestionIndex].options.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ElevatedButton(
                  onPressed: _showExplanation
                      ? null
                      : () {
                          setState(() {
                            _selectedAnswerIndex = entry.key;
                          });
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: entry.key == _selectedAnswerIndex
                        ? entry.key == widget.quiz.questions[_currentQuestionIndex].correctIndex
                            ? Colors.green
                            : Colors.red
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(entry.value),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_showExplanation)
              Card(
                color: Theme.of(context).cardColor,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Explanation:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.quiz.questions[_currentQuestionIndex].explanation,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _nextQuestionAfterExplanation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Next Question'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!_showExplanation)
              ElevatedButton(
                onPressed: _selectedAnswerIndex != null ? _nextQuestion : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Next'),
              ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
