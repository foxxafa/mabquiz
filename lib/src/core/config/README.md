# Configuration System

This directory contains the application's configuration system that manages environment-specific settings for authentication, Firebase, and build configurations.

## Overview

The configuration system automatically determines the appropriate settings based on:
- Build mode (debug vs release)
- Environment variables
- Command-line arguments

## Configuration Classes

### AppConfig
Main configuration class that orchestrates all environment-specific settings.

### FirebaseConfig
Manages Firebase-specific settings including:
- Emulator configuration for development
- Production Firebase settings
- Connection parameters

### AuthConfig
Handles authentication configuration:
- Mock vs real authentication
- Timing and behavior settings
- Persistence options

### BuildConfig
Compile-time configuration using `--dart-define` flags.

## Usage

### Development Mode (Default)
```bash
flutter run
```
- Uses Firebase emulator
- Mock authentication enabled
- Debug logging enabled

### Production Mode
```bash
flutter run --dart-define=ENVIRONMENT=production
```
- Uses real Firebase
- Real authentication
- Minimal logging

### Custom Emulator Host (for Android emulator)
```bash
flutter run --dart-define=FIREBASE_EMULATOR_HOST=10.0.2.2
```

### Force Mock Authentication
```bash
flutter run --dart-define=FORCE_MOCK_AUTH=true
```

### Disable Firebase Completely
```bash
flutter run --dart-define=DISABLE_FIREBASE=true
```

### Custom Emulator Port
```bash
flutter run --dart-define=FIREBASE_AUTH_EMULATOR_PORT=9099
```

## Build Configuration Options

| Flag | Default | Description |
|------|---------|-------------|
| `ENVIRONMENT` | `development` (debug) / `production` (release) | Sets the application environment |
| `FIREBASE_EMULATOR_HOST` | `localhost` | Firebase emulator host address |
| `FIREBASE_AUTH_EMULATOR_PORT` | `9099` | Firebase Auth emulator port |
| `FORCE_MOCK_AUTH` | `false` | Forces mock authentication regardless of environment |
| `DISABLE_FIREBASE` | `false` | Completely disables Firebase initialization |

## Firebase Emulator Setup

For development with Firebase emulator:

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Initialize Firebase emulator:
```bash
firebase init emulators
```

3. Start emulator:
```bash
firebase emulators:start --only auth
```

4. Run app with emulator:
```bash
flutter run
```

## Testing Different Configurations

### Test Mock Authentication
```bash
flutter run --dart-define=FORCE_MOCK_AUTH=true
```

### Test Production Configuration in Debug
```bash
flutter run --dart-define=ENVIRONMENT=production
```

### Test Without Firebase
```bash
flutter run --dart-define=DISABLE_FIREBASE=true
```

## Integration with Riverpod

The configuration system integrates with Riverpod providers:

- `appConfigProvider`: Main configuration
- `environmentProvider`: Current environment
- `firebaseConfigProvider`: Firebase settings
- `authConfigProvider`: Authentication settings
- `useMockAuthProvider`: Mock auth flag
- `useFirebaseEmulatorProvider`: Emulator flag

## Environment Detection

The system automatically detects the environment using:

1. `--dart-define=ENVIRONMENT` flag (highest priority)
2. `kDebugMode` from Flutter (fallback)

This ensures appropriate configuration in all scenarios while allowing manual override when needed.