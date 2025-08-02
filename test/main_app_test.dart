import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:brainsprint/main.dart';
import 'package:brainsprint/providers/theme_provider.dart';
import 'package:brainsprint/providers/gamification_provider.dart';
import 'package:brainsprint/services/gamification_service.dart';
import 'package:brainsprint/repositories/gamification/gamification_repository.dart';
import 'package:brainsprint/repositories/quiz_repository.dart';

// Mock classes for Firebase and other dependencies
class MockFirebaseApp extends Mock implements FirebaseApp {}
class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockGamificationRepository extends Mock implements GamificationRepository {}

void main() {
  // Initialize Firebase mock
  setupFirebaseMocks();
  
  late SharedPreferences prefs;
  late GamificationRepository gamificationRepo;
  
  setUp(() {
    // Setup mocks
    prefs = MockSharedPreferences();
    gamificationRepo = MockGamificationRepository();
    
    // Mock SharedPreferences
    when(prefs.getString(any)).thenReturn(null);
    when(prefs.setString(any, any)).thenAnswer((_) async => true);
    
    // Mock Firebase
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  
  // Helper function to wrap the app with necessary providers
  Widget createAppForTesting({ThemeMode initialThemeMode = ThemeMode.system}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(prefs)..setThemeMode(initialThemeMode),
        ),
        Provider<GamificationRepository>(
          create: (_) => gamificationRepo,
        ),
        ProxyProvider<GamificationRepository, GamificationService>(
          update: (_, repo, __) => GamificationService(repository: repo),
        ),
        ChangeNotifierProxyProvider<GamificationService, GamificationProvider>(
          create: (_) => GamificationProvider(),
          update: (_, service, provider) => provider!..updateService(service),
        ),
        Provider<QuizRepository>(
          create: (_) => QuizRepository(),
        ),
      ],
      child: const BrainSprintApp(),
    );
  }
  
  testWidgets('App launches and shows welcome screen', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(createAppForTesting());
    
    // Verify that the welcome screen is shown first
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
  
  testWidgets('App navigates to login screen', (WidgetTester tester) async {
    await tester.pumpWidget(createAppForTesting());
    
    // Tap the login button and trigger a frame
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    
    // Verify that the login screen is shown
    expect(find.byType(LoginScreen), findsOneWidget);
  });
  
  testWidgets('App navigates to signup screen', (WidgetTester tester) async {
    await tester.pumpWidget(createAppForTesting());
    
    // Tap the signup button and trigger a frame
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    
    // Verify that the signup screen is shown
    expect(find.byType(SignupScreen), findsOneWidget);
  });
  
  testWidgets('App handles unknown routes with error screen', (WidgetTester tester) async {
    await tester.pumpWidget(createAppForTesting());
    
    // Navigate to an unknown route
    Navigator.of(tester.element(find.byType(WelcomeScreen))).pushNamed('/unknown');
    await tester.pumpAndSettle();
    
    // Verify that the error screen is shown
    expect(find.text('Error'), findsOneWidget);
    expect(find.text('No route defined for /unknown'), findsOneWidget);
  });
  
  testWidgets('App applies light theme when set', (WidgetTester tester) async {
    await tester.pumpWidget(createAppForTesting(initialThemeMode: ThemeMode.light));
    
    // Get the theme from the MaterialApp
    final theme = Theme.of(tester.element(find.byType(MaterialApp)));
    
    // Verify that the brightness is light
    expect(theme.brightness, Brightness.light);
  });
  
  testWidgets('App applies dark theme when set', (WidgetTester tester) async {
    await tester.pumpWidget(createAppForTesting(initialThemeMode: ThemeMode.dark));
    
    // Get the theme from the MaterialApp
    final theme = Theme.of(tester.element(find.byType(MaterialApp)));
    
    // Verify that the brightness is dark
    expect(theme.brightness, Brightness.dark);
  });
}

// Setup Firebase mocks
void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Mock Firebase initialization
  when(Firebase.initializeApp(
    options: anyNamed('options'),
  )).thenAnswer((_) async => MockFirebaseApp());
}
