import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings özelliği için provider'lar

/// Dil seçimi dialog'u açık/kapalı durumu
final languageDialogProvider = StateProvider<bool>((ref) => false);

/// Tema seçimi dialog'u açık/kapalı durumu
final themeDialogProvider = StateProvider<bool>((ref) => false);
