import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/spaced_repetition_model.dart';
import '../repositories/spaced_repetition_repository.dart';
import '../services/notification_service.dart';

class SpacedRepetitionScreen extends StatefulWidget {
  const SpacedRepetitionScreen({super.key});

  @override
  State<SpacedRepetitionScreen> createState() => _SpacedRepetitionScreenState();
}

class _SpacedRepetitionScreenState extends State<SpacedRepetitionScreen> {
  final SpacedRepetitionRepository _repository = SpacedRepetitionRepository();
  List<ReviewSlot> _reviewSlots = [];
  int _selectedDay = 0; // Monday
  int _selectedHour = 9;
  int _selectedMinute = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get the preferences stream and handle null values
        final prefsStream = _repository.getPreferencesStream(user.uid);
        final prefs = await prefsStream.first;
        
        if (prefs != null) {
          setState(() {
            _reviewSlots = prefs.reviewSlots;
            if (_reviewSlots.isNotEmpty) {
              _selectedDay = _reviewSlots.first.dayOfWeek;
              _selectedHour = _reviewSlots.first.time.hour;
              _selectedMinute = _reviewSlots.first.time.minute;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Save preferences to Firestore
        await _repository.savePreferences(
          user.uid,
          SpacedRepetitionPreferences(
            reviewSlots: _reviewSlots,
            nextReviewDates: {},
            masteryLevels: {},
          ),
        );
        
        // Group review slots by day of week and convert ReviewTime to TimeOfDay
        // Convert dayOfWeek from 0-6 (0=Monday) to 1-7 (1=Monday) for notifications
        final Map<int, List<TimeOfDay>> weeklySchedule = {};
        debugPrint('=== DEBUG: Review Slots ===');
        for (final slot in _reviewSlots) {
          final timeOfDay = TimeOfDay(hour: slot.time.hour, minute: slot.time.minute);
          // Add 1 to convert from 0-6 to 1-7
          final notificationDay = slot.dayOfWeek + 1;
          weeklySchedule.putIfAbsent(notificationDay, () => []).add(timeOfDay);
          debugPrint('Day ${slot.dayOfWeek} (${slot.dayName}): ${timeOfDay.hour}:${timeOfDay.minute}');
        }
        
        // Schedule weekly notifications
        debugPrint('=== DEBUG: Weekly Schedule ===');
        weeklySchedule.forEach((day, times) {
          debugPrint('Day $day: ${times.map((t) => '${t.hour}:${t.minute}').join(', ')}');
        });
        
        final notificationService = NotificationService();
        await notificationService.scheduleWeeklyQuizNotifications(weeklySchedule);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences and weekly notifications saved successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        // Show error message if save fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save preferences: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _addReviewSlot() {
    setState(() {
      _reviewSlots.add(ReviewSlot(
        dayOfWeek: _selectedDay,
        time: ReviewTime(hour: _selectedHour, minute: _selectedMinute),
      ));
    });
  }

  void _removeReviewSlot(int index) {
    setState(() {
      _reviewSlots.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spaced Repetition Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ExpansionTile(
                  title: const Text(
                    'Review Schedule',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  initiallyExpanded: true,
                  children: [
                    const SizedBox(height: 16),
                    ..._reviewSlots.map((slot) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${slot.dayName} at ${slot.time.hour}:${slot.time.minute.toString().padLeft(2, '0')}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _removeReviewSlot(_reviewSlots.indexOf(slot)),
                        ),
                      ),
                    )),
                    const SizedBox(height: 16),
                    const Text(
                      'Add New Review Slot',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(
                          ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][_selectedDay],
                          style: const TextStyle(fontSize: 24),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: () => setState(() => _selectedDay = (_selectedDay - 1) % 7),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: () => setState(() => _selectedDay = (_selectedDay + 1) % 7),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              _selectedHour.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 24),
                            ),
                            const Text(':'),
                            Text(
                              _selectedMinute.toString().padLeft(2, '0'),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: () => setState(() => _selectedHour = (_selectedHour + 1) % 24),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: () => setState(() => _selectedHour = (_selectedHour - 1) % 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: () => setState(() => _selectedMinute = (_selectedMinute + 15) % 60),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: () => setState(() => _selectedMinute = (_selectedMinute - 15) % 60),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addReviewSlot,
                  child: const Text('Add Review Slot'),
                ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _savePreferences,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save Preferences',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
    );
  }
}
