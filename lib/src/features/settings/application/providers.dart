import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

/// Settings özelliği için provider'lar

/// Dil seçimi dialog'u açık/kapalı durumu
final languageDialogProvider = StateProvider<bool>((ref) => false);

/// Tema seçimi dialog'u açık/kapalı durumu
final themeDialogProvider = StateProvider<bool>((ref) => false);

/// Uygulama tema modu provider'ı
final themeModeProvider = StateProvider<AppThemeMode>((ref) => AppThemeMode.dark);

/// Tema provider notifier sınıfı
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.dark);

  void setLightTheme() {
    state = AppThemeMode.light;
  }

  void setDarkTheme() {
    state = AppThemeMode.dark;
  }

  void toggleTheme() {
    state = state == AppThemeMode.light ? AppThemeMode.dark : AppThemeMode.light;
  }
}

/// Tema notifier provider'ı
final themeModeNotifierProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});
