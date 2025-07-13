# Contributing to BrainSprint

First off, thank you for considering contributing to BrainSprint! We appreciate your time and effort in helping us improve this project.

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

- Ensure the bug was not already reported by searching in the [Issues](https://github.com/yourusername/brainsprint/issues).
- If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/yourusername/brainsprint/issues/new). Be sure to include:
  - A clear and descriptive title
  - Steps to reproduce the issue
  - Expected vs. actual behavior
  - Screenshots or screen recordings if applicable
  - Device and OS version

### Suggesting Enhancements

- Use the same process as for bug reports, but use the "Feature Request" label.
- Clearly describe the use case and why you believe it would be useful to other users.

### Your First Code Contribution

1. Fork the repository
2. Clone your fork locally
3. Create a new branch for your changes: `git checkout -b feature/amazing-feature`
4. Make your changes and commit them: `git commit -m 'Add some amazing feature'`
5. Push to your fork: `git push origin feature/amazing-feature`
6. Open a Pull Request

### Pull Request Process

1. Ensure any install or build dependencies are removed before the end of the layer when doing a build.
2. Update the README.md with details of changes to the interface, this includes new environment variables, exposed ports, useful file locations and container parameters.
3. Increase the version numbers in any examples files and the README.md to the new version that this Pull Request would represent. The versioning scheme we use is [SemVer](http://semver.org/).
4. You may merge the Pull Request in once you have the sign-off of two other developers, or if you do not have permission to do that, you may request the second reviewer to merge it for you.

## Development Setup

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Android Studio / Xcode (for mobile development)
- VS Code (recommended)

### Getting Started

1. Fork the repository
2. Clone your fork
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Code Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Run `dart format .` before committing
- Ensure all tests pass before submitting a PR

## License

By contributing, you agree that your contributions will be licensed under its MIT License.
