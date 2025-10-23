import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mabquiz/src/core/navigation/app_router.dart';
import 'package:mabquiz/src/core/theme/app_theme.dart';
import 'package:mabquiz/src/features/settings/application/providers.dart';
import 'package:mabquiz/src/core/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize database
  try {
    final db = await DatabaseHelper.instance.database;
    final stats = await DatabaseHelper.instance.getDatabaseStats();
    debugPrint('✅ Database initialized successfully');
    debugPrint('📊 Database stats: $stats');
  } catch (e) {
    debugPrint('❌ Database initialization failed: $e');
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('tr'),
        Locale('en'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('tr'),
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);
    
    return MaterialApp.router(
      routerConfig: appRouterProvider,
      title: 'MAB Quiz',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode == AppThemeMode.light ? ThemeMode.light : ThemeMode.dark,
    );
  }
}


