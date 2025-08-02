import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brainsprint/main.dart';
import 'package:brainsprint/screens/welcome_screen.dart';

// Mock SharedPreferences
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SharedPreferences prefs;
  
  setUp(() {
    // Setup mock SharedPreferences
    prefs = MockSharedPreferences();
    when(prefs.getString(any)).thenReturn(null);
    when(prefs.setString(any, any)).thenAnswer((_) async => true);
  });

  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    // Verify that the welcome screen shows the app title
    expect(find.text('BrainSprint'), findsOneWidget);
    
    // Verify that the login and signup buttons are present
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('App initializes without errors', (WidgetTester tester) async {
    // This test verifies that the app can be built without throwing exceptions
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WelcomeScreen(),
        ),
      ),
    );

    // Verify that the welcome screen is shown
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
