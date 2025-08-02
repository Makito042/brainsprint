import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gamification_provider.dart';
import '../../models/user_model.dart';
import '../../models/gamification/challenge_model.dart';
import '../gamification/challenges_screen.dart';

class SelectChallengeUserScreen extends StatefulWidget {
  final Map<String, dynamic> challengeData;
  
  const SelectChallengeUserScreen({
    Key? key,
    required this.challengeData,
  }) : super(key: key);

  @override
  _SelectChallengeUserScreenState createState() => _SelectChallengeUserScreenState();
}

class _SelectChallengeUserScreenState extends State<SelectChallengeUserScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<AppUser> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    if (_searchQuery.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final gamification = context.read<GamificationProvider>();
      final results = await gamification.searchUsers(_searchQuery);
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error searching users')),
        );
      }
    }
  }

  Future<void> _selectUser(AppUser user) async {
    // Get current user ID from GamificationProvider
    final gamification = context.read<GamificationProvider>();
    final currentUserId = gamification.currentUserId;
    
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to create a challenge')),
        );
      }
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Challenge'),
        content: Text('Challenge ${user.displayName ?? 'this user'} to this ${widget.challengeData['type']} challenge?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('CREATE CHALLENGE'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    // Update the challenge data with the selected user
    final updatedData = Map<String, dynamic>.from(widget.challengeData);
    updatedData['challengedUserId'] = user.uid;
    
    // If this is a quiz challenge, ensure quizId is in metadata
    if (updatedData['type'] == ChallengeType.quiz) {
      updatedData['metadata'] ??= {};
      updatedData['metadata']['quizId'] = updatedData['quizId'];
      updatedData['metadata']['challengerId'] = currentUserId;
    }
    
    // Create the challenge
    await _createChallenge(updatedData);
    
    // Show success message and navigate to upcoming challenges
    if (mounted) {
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Challenge sent to ${user.displayName ?? 'user'}!'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Navigate back to the root and then to challenges with upcoming tab
      if (context.mounted) {
        // First pop the user selection screen
        Navigator.of(context).pop();
        
        // Find the root navigator if we're in a nested navigator
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil<void>(
          MaterialPageRoute(
            builder: (context) => const ChallengesScreen(),
            settings: const RouteSettings(
              name: '/challenges',
              arguments: {'initialTab': 1}, // 1 is the index for upcoming tab
            ),
          ),
          (route) => false, // Remove all previous routes
        );
      }
    }
  }

  Future<void> _createChallenge(Map<String, dynamic> challengeData) async {
    final gamification = context.read<GamificationProvider>();
    final currentUserId = gamification.currentUserId;
    
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to create a challenge')),
        );
      }
      return;
    }
    
    try {
      final participants = [
        currentUserId,
        challengeData['challengedUserId'] as String,
      ];
      
      final challengeId = await gamification.createChallenge(
        title: challengeData['title'] as String,
        description: challengeData['description'] as String,
        type: challengeData['type'] as ChallengeType,
        startDate: challengeData['startDate'] as DateTime,
        endDate: challengeData['endDate'] as DateTime,
        rewardPoints: 100,
        metadata: challengeData['metadata'] as Map<String, dynamic>?,
        participants: participants,
      );

      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create challenge: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select User to Challenge'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name or email',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.trim());
              },
              onSubmitted: (_) => _searchUsers(),
            ),
            const SizedBox(height: 16),
            
            // Search results
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_searchResults.isEmpty && _searchQuery.isNotEmpty)
              const Center(child: Text('No users found'))
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.photoURL != null 
                            ? NetworkImage(user.photoURL!) 
                            : null,
                        child: user.photoURL == null 
                            ? Text(user.displayName?[0] ?? 'U')
                            : null,
                      ),
                      title: Text(user.displayName ?? 'No name'),
                      subtitle: Text(user.email ?? ''),
                      onTap: () async {
                        await _selectUser(user);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
