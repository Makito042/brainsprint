import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../repositories/analytics_repository.dart';
import '../../models/analytics_models.dart';

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<List<TopicMastery>>(
          create: (context) => AnalyticsRepository().getUserTopicMastery(),
          initialData: const [],
        ),
        StreamProvider<List<KnowledgeGap>>(
          create: (context) => AnalyticsRepository().getUserKnowledgeGaps(),
          initialData: const [],
        ),
        StreamProvider<List<StudyRecommendation>>(
          create: (context) => AnalyticsRepository().getStudyRecommendations(),
          initialData: const [],
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Performance Analytics'),
          elevation: 0,
        ),
        body: _AnalyticsDashboardContent(),
      ),
    );
  }
}

class _AnalyticsDashboardContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewSection(),
          const SizedBox(height: 24),
          _buildTopicMasterySection(),
          const SizedBox(height: 24),
          _buildKnowledgeGapsSection(),
          const SizedBox(height: 24),
          _buildRecommendationsSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Consumer3<List<TopicMastery>, List<KnowledgeGap>, List<StudyRecommendation>>(
      builder: (context, topics, gaps, recommendations, _) {
        final totalMastery = topics.isEmpty
            ? 0.0
            : topics.map((t) => t.masteryScore).reduce((a, b) => a + b) / topics.length;
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Performance Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      '${(totalMastery * 100).toStringAsFixed(1)}%',
                      'Overall Mastery',
                      Icons.auto_graph,
                    ),
                    _buildStatCard(
                      gaps.length.toString(),
                      'Knowledge Gaps',
                      Icons.warning_amber,
                    ),
                    _buildStatCard(
                      recommendations.length.toString(),
                      'Recommendations',
                      Icons.lightbulb_outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopicMasterySection() {
    return Consumer<List<TopicMastery>>(
      builder: (context, topics, _) {
        if (topics.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Topic Mastery',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 1.0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipBgColor: Colors.blueGrey,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            return BarTooltipItem(
                              '${topics[groupIndex].topicName}\n${(rod.toY * 100).toStringAsFixed(1)}%',
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < topics.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    topics[value.toInt()]
                                        .topicName
                                        .split(' ')
                                        .map((w) => w.isNotEmpty ? w[0] : '')
                                        .join(),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: topics.asMap().entries.map((entry) {
                        final index = entry.key;
                        final topic = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: topic.masteryScore,
                              color: _getMasteryColor(topic.masteryScore),
                              width: 16,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKnowledgeGapsSection() {
    return Consumer<List<KnowledgeGap>>(
      builder: (context, gaps, _) {
        if (gaps.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Knowledge Gaps',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...gaps.take(3).map((gap) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    title: Text(
                      gap.topicName,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      '${(gap.gapSeverity * 100).toStringAsFixed(0)}% gap severity',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to topic details
                    },
                  ),
                )),
                if (gaps.length > 3)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Show all knowledge gaps
                      },
                      child: const Text('View All'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationsSection() {
    return Consumer<List<StudyRecommendation>>(
      builder: (context, recommendations, _) {
        if (recommendations.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Study Recommendations',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...recommendations.take(3).map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    leading: _getRecommendationIcon(rec.type),
                    title: Text(
                      rec.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(rec.description),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Handle recommendation tap
                    },
                  ),
                )),
                if (recommendations.length > 3)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Show all recommendations
                      },
                      child: const Text('View All'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Builder(
      builder: (context) => Column(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getMasteryColor(double score) {
    if (score < 0.4) return Colors.red;
    if (score < 0.7) return Colors.orange;
    if (score < 0.9) return Colors.lightGreen;
    return Colors.green;
  }

  Widget _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.study:
        return const Icon(Icons.menu_book, color: Colors.blue);
      case RecommendationType.practice:
        return const Icon(Icons.quiz, color: Colors.purple);
      case RecommendationType.review:
        return const Icon(Icons.refresh, color: Colors.orange);
      case RecommendationType.examPrep:
        return const Icon(Icons.assignment, color: Colors.red);
      case RecommendationType.resource:
        return const Icon(Icons.library_books, color: Colors.green);
      case RecommendationType.timeManagement:
        return const Icon(Icons.timer, color: Colors.teal);
    }
  }
}
