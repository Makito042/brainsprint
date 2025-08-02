import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gamification_provider.dart';
import '../../models/gamification/challenge_model.dart';
import '../../models/quiz_model.dart';
import '../../widgets/quiz_selection_dialog.dart';
import 'select_challenge_user_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Move quiz selection state to widget level
  String? selectedQuizId;
  String? selectedQuizTitle;

  Future<void> _loadChallenges() async {
    try {
      // This method is called to load challenges when the screen initializes
      // The actual loading is handled by the GamificationProvider
      debugPrint('Loading challenges...');
    } catch (e) {
      debugPrint('Error loading challenges: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load challenges')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Challenges'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Active'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            indicatorColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).hintColor,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<GamificationProvider>().refresh(),
            ),
          ],
        ),
        body: Consumer<GamificationProvider>(
          builder: (context, gamification, _) {
            if (gamification.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (gamification.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load challenges',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gamification.error!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: gamification.refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              children: [
                _buildChallengesList(
                  context,
                  gamification.activeChallenges,
                  'No active challenges',
                  'Check back later for new challenges!',
                  gamification,
                ),
                _buildChallengesList(
                  context,
                  gamification.upcomingChallenges,
                  'No upcoming challenges',
                  'New challenges will appear here when available!',
                  gamification,
                ),
                _buildChallengesList(
                  context,
                  gamification.completedChallenges,
                  'No completed challenges yet',
                  'Complete challenges to see them here!',
                  gamification,
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Show create challenge dialog
            _showCreateChallengeDialog(context);
          },
          icon: const Icon(Icons.add),
          label: const Text('Create Challenge'),
        ),
      ),
    );
  }

  Widget _buildChallengesList(
    BuildContext context,
    List<Challenge> challenges,
    String emptyTitle,
    String emptySubtitle,
    GamificationProvider gamification,
  ) {
    if (challenges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.flag_outlined,
                size: 64,
                color: Theme.of(context).hintColor,
              ),
              const SizedBox(height: 16),
              Text(
                emptyTitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                emptySubtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        return _buildChallengeCard(context, challenge, gamification);
      },
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    Challenge challenge,
    GamificationProvider gamification,
  ) {
    final isParticipant = challenge.participants
        .contains(gamification.currentUserId);
    final timeRemaining = gamification.getTimeRemaining(challenge);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Show challenge details
          _showChallengeDetails(context, challenge, gamification);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.flag, color: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${challenge.participants.length} participants • $timeRemaining',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (gamification.isChallengeJoinable(challenge))
                    ElevatedButton(
                      onPressed: () {
                        if (isParticipant) {
                          gamification.leaveChallenge(challenge.challengeId);
                        } else {
                          gamification.joinChallenge(challenge.challengeId);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isParticipant
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: isParticipant
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: Text(isParticipant ? 'Leave' : 'Join'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                challenge.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: challenge.participants.length / 20,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                color: Theme.of(context).colorScheme.primary,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${challenge.participants.length} of 20 participants',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  Text(
                    '${challenge.rewardPoints} pts',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChallengeDetails(
    BuildContext context,
    Challenge challenge,
    GamificationProvider gamification,
  ) {
    final isParticipant = challenge.participants
        .contains(gamification.currentUserId);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => ChallengeDetailsSheet(
          challenge: challenge,
          isParticipant: isParticipant,
          gamification: gamification,
        ),
      ),
    );
  }

  void _showCreateChallengeDialog(BuildContext context) {
    final gamification = context.read<GamificationProvider>();
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final endDateController = TextEditingController();
    
    // Local state for the dialog
    String? dialogQuizId = selectedQuizId;
    String? dialogQuizTitle = selectedQuizTitle;
    ChallengeType selectedType = ChallengeType.quiz; // Default to quiz challenge
    DateTime? selectedEndDate;
    
    // Navigate to user selection screen with the challenge data
    void _navigateToUserSelection() {
      if (!formKey.currentState!.validate()) return;
      
      if (selectedEndDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an end date')),
        );
        return;
      }

      if (selectedType == ChallengeType.quiz && selectedQuizId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a quiz')),
        );
        return;
      }

      // Prepare challenge data
      final challengeData = {
        'title': titleController.text,
        'description': descriptionController.text,
        'type': selectedType,
        'startDate': DateTime.now(),
        'endDate': selectedEndDate!,
        'metadata': {
          'quizId': dialogQuizId,
          'quizTitle': dialogQuizTitle,
          'challengerId': gamification.currentUserId,
          'challengedUserId': null, // Will be set when selecting a user
          'challengerScore': null,
          'challengedUserScore': null,
          'challengerCompleted': false,
          'challengedUserCompleted': false,
        },
      };

      // Navigate to user selection screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SelectChallengeUserScreen(
            challengeData: challengeData,
          ),
        ),
      );
    }

    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 7)),
        firstDate: DateTime.now().add(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365)),
      );
      if (picked != null) {
        selectedEndDate = picked;
        endDateController.text = '${picked.year}-${picked.month}-${picked.day}';
      }
    }

    Future<void> _selectQuiz(BuildContext context) async {
      try {
        final quiz = await showQuizSelectionDialog(context);
        
        if (quiz != null && mounted) {
          // Update the state in a single setState call
          setState(() {
            selectedQuizId = quiz.id;
            selectedQuizTitle = quiz.title;
            debugPrint('Selected quiz: ${quiz.title} (${quiz.id})');
          });
          
          // Show a snackbar to confirm selection
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected quiz: ${quiz.title}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error selecting quiz: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error loading quizzes. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }



    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Create New Challenge'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Challenge Type
                      DropdownButtonFormField<ChallengeType>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Challenge Type',
                          border: OutlineInputBorder(),
                        ),
                        items: ChallengeType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toString().split('.').last),
                          );
                        }).toList(),
                        onChanged: (type) {
                          if (type != null) {
                            setDialogState(() {
                              selectedType = type;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Title
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // End Date
                      TextFormField(
                        controller: endDateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an end date';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Quiz Selection (only for quiz challenges)
                      if (selectedType == ChallengeType.quiz) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected Quiz',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (dialogQuizTitle != null) ...[
                                    Text(
                                      dialogQuizTitle!,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: $dialogQuizId',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ] else ...[
                                    const Text(
                                      'No quiz selected',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final quiz = await showQuizSelectionDialog(context);
                                  if (quiz != null && mounted) {
                                    setDialogState(() {
                                      dialogQuizId = quiz.id;
                                      dialogQuizTitle = quiz.title;
                                    });
                                    if (mounted) {
                                      setState(() {
                                        selectedQuizId = quiz.id;
                                        selectedQuizTitle = quiz.title;
                                      });
                                    }
                                  }
                                },
                                icon: const Icon(Icons.search, size: 16),
                                label: Text(
                                  dialogQuizId == null ? 'Select Quiz' : 'Change Quiz',
                                ),
                              ),
                            ),
                            if (selectedType == ChallengeType.quiz && dialogQuizId == null)
                              const Text(
                                'Please select a quiz',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: _navigateToUserSelection,
                  child: const Text('NEXT'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ChallengeDetailsSheet extends StatelessWidget {
  final Challenge challenge;
  final bool isParticipant;
  final GamificationProvider gamification;

  const ChallengeDetailsSheet({
    super.key,
    required this.challenge,
    required this.isParticipant,
    required this.gamification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag, color: Colors.red, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${challenge.participants.length} participants • ${gamification.getTimeRemaining(challenge)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Challenge Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildDetailChip(
                context,
                Icons.emoji_events,
                '${challenge.rewardPoints} pts',
              ),
              const SizedBox(width: 8),
              _buildDetailChip(
                context,
                Icons.people,
                '${challenge.participants.length} participants',
              ),
              const SizedBox(width: 8),
              _buildDetailChip(
                context,
                Icons.calendar_today,
                'Ends ${_formatDate(challenge.endDate)}',
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (gamification.isChallengeJoinable(challenge))
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (isParticipant) {
                    gamification.leaveChallenge(challenge.challengeId);
                  } else {
                    gamification.joinChallenge(challenge.challengeId);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: isParticipant
                      ? Theme.of(context).colorScheme.errorContainer
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: isParticipant
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(
                  isParticipant ? 'Leave Challenge' : 'Join Challenge',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          const Spacer(),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Challenge ends ${_formatDate(challenge.endDate)}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(
    BuildContext context, 
    IconData icon, 
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).hintColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${_getMonth(date.month)} ${date.day}, ${date.year}';
  }

  static String _getMonth(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
