import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // In a real app, you would fetch notifications from your backend
    // For now, we'll use some sample data
    setState(() {
      _notifications.addAll([
        {
          'title': 'Quiz Reminder',
          'body': 'Your scheduled quiz is ready!',
          'time': tz.TZDateTime.now(tz.local).subtract(const Duration(minutes: 5)),
          'read': false,
        },
        {
          'title': 'New Quiz Available',
          'body': 'Check out the new Reflective Thinking quiz!',
          'time': tz.TZDateTime.now(tz.local).subtract(const Duration(hours: 2)),
          'read': true,
        },
      ]);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              // Mark all as read
              setState(() {
                for (var notification in _notifications) {
                  notification['read'] = true;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text('No notifications yet'),
                )
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return _buildNotificationItem(notification);
                  },
                ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    return Container(
      decoration: BoxDecoration(
        color: notification['read'] ? null : Colors.blue.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            Icons.quiz_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          notification['title'],
          style: TextStyle(
            fontWeight: notification['read'] ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification['body']),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, y • h:mm a').format(notification['time']),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () {
          // Mark as read when tapped
          if (!notification['read']) {
            setState(() {
              notification['read'] = true;
            });
          }
          // Handle notification tap
        },
      ),
    );
  }
}
