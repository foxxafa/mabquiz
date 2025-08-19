import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Desteklenen diller enum'u
enum SupportedLanguage {
  turkish('tr', 'TR', 'Türkçe', '🇹🇷'),
  english('en', 'US', 'English', '🇺🇸');

  const SupportedLanguage(this.languageCode, this.countryCode, this.name, this.flag);
  
  final String languageCode;
  final String countryCode;
  final String name;
  final String flag;
  
  Locale get locale => Locale(languageCode);
}

/// Lokalizasyon hizmet sınıfı
class LocalizationService {
  /// Dili değiştir
  static Future<void> changeLanguage(BuildContext context, SupportedLanguage language) async {
    await context.setLocale(language.locale);
  }
  
  /// Mevcut dili al
  static SupportedLanguage getCurrentLanguage(BuildContext context) {
    final currentLocale = context.locale;
    
    for (final language in SupportedLanguage.values) {
      if (language.locale.languageCode == currentLocale.languageCode) {
        return language;
      }
    }
    
    return SupportedLanguage.turkish; // Fallback
  }
  
  /// Desteklenen dilleri al
  static List<SupportedLanguage> getSupportedLanguages() {
    return SupportedLanguage.values;
  }
}

/// Context extension for easy localization
extension EasyLocalizationExtension on BuildContext {
  /// Çeviri metni al
  String translate(String key, {List<String>? args, Map<String, String>? namedArgs}) {
    return key.tr(args: args, namedArgs: namedArgs);
  }
  
  /// Mevcut dili al
  SupportedLanguage get currentLanguage {
    return LocalizationService.getCurrentLanguage(this);
  }
  
  /// Dili değiştir
  Future<void> changeLanguage(SupportedLanguage language) async {
    await LocalizationService.changeLanguage(this, language);
  }
}
