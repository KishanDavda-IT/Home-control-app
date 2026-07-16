# Contributing to LightFan Controller

Thank you for considering contributing to LightFan Controller! We welcome contributions from the community.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

- **Device Information**: What Shelly device(s) are you using? (e.g., Shelly 1, Shelly Plus 1, etc.)
- **Firmware Version**: What firmware version is running on your device?
- **Mobile Device**: What phone/tablet and OS version are you using?
- **Steps to Reproduce**: Clear steps to reproduce the issue
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Screenshots**: If applicable, include screenshots to help demonstrate the problem

### Suggesting Features

Feature requests are welcome! Please provide:

- **Clear Description**: What feature would you like to see?
- **Use Case**: Why would this feature be useful?
- **Alternative Solutions**: Have you considered alternative solutions?

### Pull Requests

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Ensure your code follows the project's coding standards
5. Run tests to ensure nothing is broken
6. Commit your changes (`git commit -am 'Add amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Create a new Pull Request

## Development Setup

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.4.0 or higher)
- Android Studio / VS Code with Flutter & Dart plugins
- A physical device or emulator for testing

### Getting Started

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/yourusername/lightfan-controller.git
   cd lightfan-controller
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Running Tests

To run unit tests:
```bash
flutter test
```

To run widget tests:
```bash
flutter test test/
```

### Code Style

This project follows the [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines. We recommend using:

- `flutter analyze` for static analysis
- `flutter format` for code formatting

### Reporting Security Issues

Please do not report security vulnerabilities through public GitHub issues. Instead, please email security@lightfan-controller.example with your findings.

## Getting Help

If you need help with your contribution, please:

1. Check the existing issues
2. Ask questions in the Discussions section
3. Reach out to maintainers

Thank you again for contributing to LightFan Controller!