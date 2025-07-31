import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/spaced_repetition_screen.dart';
import 'services/notification_service.dart';
import 'services/gamification_service.dart';
import 'repositories/gamification/gamification_repository.dart';
import 'repositories/quiz_repository.dart';
import 'providers/theme_provider.dart';
import 'providers/gamification_provider.dart';
import 'core/themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestNotificationPermission();
  
  // Set preferred orientations to allow both portrait and landscape
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  final prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        Provider<GamificationRepository>(
          create: (_) => GamificationRepository(),
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
    ),
  );
}

class BrainSprintApp extends StatelessWidget {
  const BrainSprintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'BrainSprint',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
      initialRoute: '/welcome',
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/auth': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/spaced-repetition': (context) => SpacedRepetitionScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle any undefined routes
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
      },
        );
      },
    );
  }
}
