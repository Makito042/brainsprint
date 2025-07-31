import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gamification_provider.dart';
import '../../models/gamification/leaderboard_model.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboards'),
          centerTitle: true,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Global'),
              Tab(text: 'Weekly'),
              Tab(text: 'Course'),
            ],
            labelColor: Theme.of(context).colorScheme.primary,
            indicatorColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).hintColor,
          ),
        ),
        body: const TabBarView(
          children: [
            LeaderboardView(leaderboardType: LeaderboardType.allTime),
            LeaderboardView(leaderboardType: LeaderboardType.weekly),
            LeaderboardView(leaderboardType: LeaderboardType.course),
          ],
        ),
      ),
    );
  }
}

class LeaderboardView extends StatelessWidget {
  final LeaderboardType leaderboardType;
  
  const LeaderboardView({
    super.key,
    required this.leaderboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GamificationProvider>(
      builder: (context, gamification, _) {
        final leaderboard = gamification.leaderboards.firstWhere(
          (lb) => lb.type == leaderboardType,
          orElse: () => Leaderboard(
            leaderboardId: 'empty',
            type: leaderboardType,
            startDate: DateTime.now(),
            entries: [],
          ),
        );

        if (leaderboard.entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.leaderboard_outlined,
                  size: 64,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No data available',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete activities to appear on the leaderboard!',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final currentUserId = gamification.currentUserId;
        final currentUserRank = leaderboard.entries
            .indexWhere((e) => e.userId == currentUserId);

        return RefreshIndicator(
          onRefresh: gamification.refresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaderboard.entries.length,
            itemBuilder: (context, index) {
              final entry = leaderboard.entries[index];
              final isCurrentUser = entry.userId == currentUserId;
              
              return _buildLeaderboardEntry(
                context,
                entry: entry,
                rank: index + 1,
                isCurrentUser: isCurrentUser,
                gamification: gamification,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardEntry(
    BuildContext context, {
    required LeaderboardEntry entry,
    required int rank,
    required bool isCurrentUser,
    required GamificationProvider gamification,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isCurrentUser
          ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
          : null,
      child: ListTile(
        leading: _buildRankBadge(rank, context),
        title: Text(
          entry.username,
          style: TextStyle(
            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              gamification.formatPoints(entry.score),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        onTap: () {
          // Show user profile or details
        },
      ),
    );
  }

  Widget _buildRankBadge(int rank, BuildContext context) {
    Color badgeColor;
    IconData? icon;

    switch (rank) {
      case 1:
        badgeColor = Colors.amber;
        icon = Icons.emoji_events;
        break;
      case 2:
        badgeColor = Colors.grey[400]!;
        icon = Icons.emoji_events;
        break;
      case 3:
        badgeColor = Colors.brown[400]!;
        icon = Icons.emoji_events;
        break;
      default:
        badgeColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: Colors.white, size: 20)
            : Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
