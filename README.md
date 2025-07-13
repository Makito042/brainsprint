# BrainSprint

A modern, cross-platform mobile application for interactive learning and quiz-based education. Built with Flutter, BrainSprint provides an engaging platform for users to test their knowledge, track progress, and enhance their learning experience.

## Features

- 🚀 **User Authentication** - Secure signup and login flow
- 📊 **Interactive Quizzes** - Engaging quiz interface with various question types
- 📈 **Progress Tracking** - Monitor your learning journey with detailed analytics
- 🎨 **Modern UI** - Beautiful, responsive design with light/dark theme support
- 🔄 **Offline Support** - Continue learning even without an internet connection
- 🌍 **Localization Ready** - Built with internationalization in mind

## Tech Stack

- **Framework**: Flutter 3.x
- **State Management**: Riverpod
- **Navigation**: Go Router
- **UI**: Material Design 3
- **Local Storage**: Shared Preferences
- **Networking**: Dio
- **Form Handling**: Form Validator
- **Testing**: Mockito & Mocktail

## Getting Started

### Prerequisites

- Flutter SDK (3.x or later)
- Dart SDK (3.x or later)
- Android Studio / Xcode (for emulator/simulator)
- VS Code or Android Studio (recommended for development)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/brainsprint.git
   cd brainsprint
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/               # Core utilities, constants, themes
├── models/             # Data models
├── providers/          # State management
├── routes/             # App navigation
├── screens/            # UI screens
│   ├── auth/           # Authentication screens
│   ├── dashboard/      # Main app screens
│   ├── quiz/           # Quiz-related screens
│   └── profile/        # User profile screens
├── services/           # Business logic and API calls
└── widgets/            # Reusable UI components
```

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Flutter Team for the amazing framework
- All contributors who helped shape this project

## Support

For support, email support@brainsprint.com or open an issue on GitHub.
