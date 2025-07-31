import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/spaced_repetition_repository.dart';

// Global navigator key for accessing context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  final SpacedRepetitionRepository _repository;

  NotificationService._internal() : _repository = SpacedRepetitionRepository();

  factory NotificationService() {
    return _instance;
  }

  Future<void> initialize() async {
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: null,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: null, // Set to null if not targeting macOS
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap here if needed
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
  }

  /// Schedules weekly notifications for quiz reminders
  /// [schedule] is a map where keys are weekdays (1-7, where 1 is Monday)
  /// and values are lists of times for that day
  Future<void> scheduleWeeklyQuizNotifications(Map<int, List<TimeOfDay>> schedule) async {
    debugPrint('=== NOTIFICATION SERVICE: Starting to schedule notifications ===');
    debugPrint('Received schedule with ${schedule.length} days');
    
    // Print the full schedule for debugging
    schedule.forEach((day, times) {
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final dayName = day >= 1 && day <= 7 ? dayNames[day - 1] : 'Unknown day';
      final timeStrings = times.map((t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}').join(', ');
      debugPrint('Day $day ($dayName): $timeStrings');
    });
    
    // Cancel all existing notifications
    await _notificationsPlugin.cancelAll();
    debugPrint('Cancelled all previous notifications');
    
    int notificationId = 0;
    
    // Schedule each time slot as a separate notification,
    // but include all times for the day in each notification
    for (final entry in schedule.entries) {
      final dayOfWeek = entry.key;
      final times = entry.value;
      
      debugPrint('Scheduling notifications for day $dayOfWeek with ${times.length} time slots');
      
      // Create a unique ID for each time slot
      for (final time in times) {
        debugPrint('  - Time slot: ${time.hour}:${time.minute} (ID: $notificationId)');
        try {
          await _scheduleWeeklyNotification(
            id: notificationId++,
            dayOfWeek: dayOfWeek,
            time: time,
            allDayTimes: times, // Pass all times for the day
          );
          debugPrint('  ✓ Successfully scheduled notification ID: ${notificationId - 1}');
        } catch (e) {
          debugPrint('  ✗ Error scheduling notification: $e');
        }
      }
    }
    
    debugPrint('=== NOTIFICATION SERVICE: Finished scheduling $notificationId notifications ===');
    
    debugPrint('Scheduled $notificationId weekly notifications');
  }
  
  /// Converts a weekday (1-7) to a DateTimeComponents value
  /// Note: Flutter's DateTimeComponents doesn't have specific day enums,
  /// so we'll use dayOfWeekAndTime and handle the day logic in the scheduling
  DateTimeComponents _getDateTimeComponents(int dayOfWeek) {
    return DateTimeComponents.dayOfWeekAndTime;
  }

  // Helper method to format time with AM/PM
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  Future<NotificationDetails> _getNotificationDetails() async {
    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'quiz_channel',
      'Quiz Notifications',
      channelDescription: 'Notifications for scheduled quiz times',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      styleInformation: InboxStyleInformation(
        [],
        contentTitle: '📚 BrainSprint Quiz Time!',
        summaryText: 'Your scheduled quiz sessions',
      ),
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required int dayOfWeek,
    required TimeOfDay time,
    required List<TimeOfDay> allDayTimes,
  }) async {
    // Get the weekday name for the notification message
    final weekdayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    final weekdayName = weekdayNames[dayOfWeek - 1];
    
    // Get current day's name
    final today = DateTime.now().weekday; // 1 (Monday) to 7 (Sunday)
    
    // Get the weekly schedule
    final weeklySchedule = await _getWeeklySchedule();
    
    // Format the current day's times
    final currentDayTimes = allDayTimes
        .map((t) => '• ${_formatTime(t)}${t.hour == time.hour && t.minute == time.minute ? ' (Now ⏰)' : ''}')
        .join('\n');
    
    final title = '📚 BrainSprint Quiz Time!';
    String body = '';
    
    // Add today's schedule
    if (weeklySchedule.isNotEmpty) {
      body += '📅 Your Weekly Quiz Schedule\n\n';
      
      // Add each day's schedule
      weeklySchedule.forEach((dayName, times) {
        if (times.isNotEmpty) {
          final isToday = dayName == weekdayName;
          final dayHeader = isToday ? '✅ $dayName (Today)' : '📌 $dayName';
          final timesList = times.map((t) => '   • ${_formatTime(t)}').join('\n');
          body += '$dayHeader\n$timesList\n\n';
        }
      });
      
      // Add current session highlight
      body += '\n⏰ Current session: ${_formatTime(time)}\n';
      body += 'Ready to train your brain? 🧠';
    } else {
      // Fallback if no schedule is found
      body = 'Your quiz session is starting now at ${_formatTime(time)}. Ready to train your brain? 🧠';
    }
    
    debugPrint('Scheduling notification for $weekdayName at ${_formatTime(time)}');
    // Create a TZDateTime for the next occurrence of this day and time
    final now = tz.TZDateTime.now(tz.local);
    
    // Find the next occurrence of the specified day of week
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    // Calculate days to add to reach the next occurrence of the target day
    int currentWeekday = scheduledDate.weekday; // 1 (Monday) to 7 (Sunday)
    int daysToAdd = (dayOfWeek - currentWeekday) % 7;
    
    // If the time has already passed today, schedule for next week
    if (daysToAdd == 0 && scheduledDate.isBefore(now)) {
      daysToAdd = 7; // Move to the same day next week
    } else if (daysToAdd < 0) {
      daysToAdd += 7; // Move to next week's occurrence
    }
    
    scheduledDate = scheduledDate.add(Duration(days: daysToAdd));

    // Get notification details
    final platformDetails = await _getNotificationDetails();

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getDateTimeComponents(dayOfWeek),
        payload: 'weekly_quiz_reminder',
      );
      debugPrint('Scheduled notification for $weekdayName at ${time.hour}:${time.minute}');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
      rethrow;
    }
  }

  Future<Map<String, List<TimeOfDay>>> _getWeeklySchedule() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('No user logged in');
        return {};
      }
      
      // Get the preferences
      debugPrint('Fetching preferences for user: ${user.uid}');
      final prefs = await _repository.getPreferencesStream(user.uid).first;
      if (prefs == null) {
        debugPrint('No preferences found for user');
        return {};
      }
      
      debugPrint('Found ${prefs.reviewSlots.length} review slots in preferences');
      
      // Group slots by day
      final Map<String, List<TimeOfDay>> weeklySchedule = {};
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      
      for (int i = 0; i < 7; i++) {
        final daySlots = prefs.reviewSlots
            .where((slot) {
              final matches = slot.dayOfWeek == i;
              if (matches) {
                debugPrint('Found slot for ${dayNames[i]}: ${slot.time.hour}:${slot.time.minute}');
              }
              return matches;
            })
            .map((slot) => TimeOfDay(hour: slot.time.hour, minute: slot.time.minute))
            .toList()
          ..sort((a, b) => a.hour * 60 + a.minute - (b.hour * 60 + b.minute)); // Sort by time
          
        if (daySlots.isNotEmpty) {
          weeklySchedule[dayNames[i]] = daySlots;
          debugPrint('Added ${daySlots.length} slots for ${dayNames[i]}');
        }
      }
      
      debugPrint('Weekly schedule prepared with ${weeklySchedule.length} days');
      return weeklySchedule;
    } catch (e) {
      debugPrint('Error getting weekly schedule: $e');
      return {};
    }
  }

  // Request notification permissions
  Future<bool> requestNotificationPermission() async {
    try {
      // For Android 13+ (API level 33+), we need to request the runtime permission
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      if (androidPlugin != null) {
        // On Android, we'll just return true as the permission is handled by the system
        // when the first notification is shown
        return true;
      }
      
      // For iOS, the plugin will handle the permission request when showing the first notification
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }
}
