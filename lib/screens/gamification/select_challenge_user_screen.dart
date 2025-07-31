import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gamification_provider.dart';
import '../../models/user_model.dart';
import '../../models/gamification/challenge_model.dart';

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

  void _selectUser(AppUser user) {
    // Update the challenge data with the selected user
    final updatedData = Map<String, dynamic>.from(widget.challengeData);
    updatedData['challengedUserId'] = user.uid;
    
    // Create the challenge
    _createChallenge(updatedData);
  }

  Future<void> _createChallenge(Map<String, dynamic> challengeData) async {
    final gamification = context.read<GamificationProvider>();
    
    try {
      final challengeId = await gamification.createChallenge(
        title: challengeData['title'] as String,
        description: challengeData['description'] as String,
        type: challengeData['type'] as ChallengeType,
        startDate: challengeData['startDate'] as DateTime,
        endDate: challengeData['endDate'] as DateTime,
        rewardPoints: 100,
        metadata: challengeData['metadata'] as Map<String, dynamic>?,
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
          const SnackBar(content: Text('Failed to create challenge')),
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
                      onTap: () => _selectUser(user),
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
