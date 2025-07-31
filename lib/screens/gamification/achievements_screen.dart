import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gamification_provider.dart';
import '../../models/gamification/achievement_model.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Achievements'),
        centerTitle: true,
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
                    'Failed to load achievements',
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

          final unlockedAchievements = gamification.achievements
              .where((a) => a.isUnlocked)
              .toList();
          final lockedAchievements = gamification.achievements
              .where((a) => !a.isUnlocked)
              .toList();

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  child: TabBar(
                    tabs: const [
                      Tab(text: 'Unlocked'),
                      Tab(text: 'Locked'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).hintColor,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAchievementsList(
                        context,
                        unlockedAchievements,
                        true,
                        gamification,
                      ),
                      _buildAchievementsList(
                        context,
                        lockedAchievements,
                        false,
                        gamification,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementsList(
    BuildContext context,
    List<UserAchievement> achievements,
    bool isUnlocked,
    GamificationProvider gamification,
  ) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUnlocked ? Icons.emoji_events_outlined : Icons.lock_outline,
              size: 64,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              isUnlocked
                  ? 'No achievements unlocked yet!'
                  : 'No locked achievements',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isUnlocked
                  ? 'Complete challenges and activities to earn achievements!'
                  : 'Keep going to unlock more achievements!',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementItem(context, achievement, gamification);
      },
    );
  }

  Widget _buildAchievementItem(
    BuildContext context,
    UserAchievement achievement,
    GamificationProvider gamification,
  ) {
    final progress = gamification.getAchievementProgress(achievement);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Achievement Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Achievement Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      if (achievement.isUnlocked) ...[
                        const Icon(Icons.verified, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '${achievement.points} pts',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (!achievement.isUnlocked) ...[
                    LinearProgressIndicator(
                      value: progress / 100,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: Theme.of(context).colorScheme.primary,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${progress.toStringAsFixed(0)}% complete',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(achievement.achievedAt),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonth(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
