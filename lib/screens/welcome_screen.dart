import 'package:flutter/material.dart';
import 'auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Image at the top (full width)
          Image.asset(
            'assets/image 1.jpg',
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.5, // 50% of screen height
            fit: BoxFit.cover,
          ),
          
          // Welcome content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
            child: Column(
              children: [
                // Welcome to BrainSprint
                const Text(
                  'Welcome to BrainSprint',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // Description text
                const Text(
                  'Get ready to challenge your mind and boost your cognitive skills with our fun and engaging brain training exercises.',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Get Started button at the bottom
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 60),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935), // Red color
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
