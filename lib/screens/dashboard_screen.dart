import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz/department_selection_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _isLoading = false;
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error signing out')),
        );
      }
    }
  }

  Future<void> _resendVerification() async {
    try {
      await _user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Please check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending verification email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              _user.displayName ?? 'User',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              _user.email ?? 'No email',
              style: const TextStyle(fontSize: 14),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _user.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(fontSize: 40, color: Color(0xFFE53935)),
              ),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.black87),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to profile screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Colors.black87),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to settings screen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _signOut();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'BrainSprint',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black),
            onPressed: () {
              // TODO: Show help dialog
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to BrainSprint',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Unlock your learning potential with our innovative features.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_user.emailVerified)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Please verify your email to access all features.',
                          style: TextStyle(color: Colors.orange),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _resendVerification,
                          child: const Text('Resend Verification Email'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // Features List
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DepartmentSelectionScreen(),
                          ),
                        );
                      },
                      child: _buildFeatureItem(
                        icon: Icons.psychology_outlined,
                        title: 'Adaptive Quizzing',
                        description: 'Personalized quizzes that adapt to your learning pace.',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(
                      icon: Icons.access_time_outlined,
                      title: 'Spaced Repetition',
                      description: 'Optimize your study schedule for long-term retention.',
                      color: Colors.green,
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(
                      icon: Icons.show_chart_outlined,
                      title: 'Performance Analytics',
                      description: 'Track your progress and identify areas for improvement.',
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(
                      icon: Icons.emoji_events_outlined,
                      title: 'Gamification',
                      description: 'Earn rewards and compete with friends to stay motivated.',
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            
            // Get Started Button
            Container(
              padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Handle get started
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
