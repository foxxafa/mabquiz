@echo off
echo Building Flutter app for production...

REM Build for production
flutter build apk --dart-define=USE_RAILWAY=true --release

echo Production build completed!