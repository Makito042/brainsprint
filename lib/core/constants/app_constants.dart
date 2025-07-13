class AppConstants {
  // App Info
  static const String appName = 'BrainSprint';
  static const String appVersion = '1.0.0';
  
  // API Endpoints
  static const String baseUrl = 'https://api.brainsprint.com';
  
  // Local Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String themeModeKey = 'theme_mode';
  
  // Default Values
  static const int defaultPageSize = 10;
  static const int maxQuizQuestions = 20;
  
  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration buttonPressDuration = Duration(milliseconds: 100);
  
  // Padding/Margin
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  
  // Other
  static const String supportEmail = 'support@brainsprint.com';
}
