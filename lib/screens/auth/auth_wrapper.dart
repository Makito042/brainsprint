import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../dashboard_screen.dart';

// This widget handles the authentication state of the app
// It shows the login screen if the user is not authenticated
// or the dashboard if the user is authenticated

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if we have a user
        final user = snapshot.data;
        
        if (user == null) {
          // User is not logged in, show login screen
          return const LoginScreen(key: ValueKey('login_screen'));
        }

        // Check if email is verified
        if (!user.emailVerified) {
          // Show a message that the email needs to be verified
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Please verify your email address.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await user.sendEmailVerification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verification email sent. Please check your inbox.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    child: const Text('Resend Verification Email'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        // User is logged in and email is verified, show main app
        return const DashboardScreen(key: ValueKey('dashboard_screen'));
      },
    );
  }
}
