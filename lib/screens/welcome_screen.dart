import 'package:flutter/material.dart';
import 'auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image at the top (full width)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Image.asset(
                          'assets/image 1.jpg',
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      
                      // Welcome content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Welcome to BrainSprint
                              Text(
                                'Welcome to BrainSprint',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.headlineMedium?.color ?? Colors.black,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Description text
                              Text(
                                'Get ready to challenge your mind and boost your cognitive skills with our fun and engaging brain training exercises.',
                                style: TextStyle(
                                  color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.9) ?? Colors.black87,
                                  fontSize: 16,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const Spacer(),
                              
                              // Get Started button at the bottom
                              Padding(
                                padding: const EdgeInsets.only(bottom: 24.0, top: 16.0),
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
