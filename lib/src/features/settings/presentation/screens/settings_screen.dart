import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/application/providers.dart';
import '../../../../core/localization/localization_provider.dart';
import '../widgets/language_selector_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentLanguage = context.currentLanguage;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('settings.title'.tr()),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: Icon(Icons.language, color: theme.colorScheme.primary),
            title: Text('settings.language'.tr()),
            subtitle: Text(currentLanguage.name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context),
          ),
          ListTile(
            leading: Icon(Icons.color_lens, color: theme.colorScheme.primary),
            title: Text('settings.theme'.tr()),
            subtitle: Text('settings.dark_mode'.tr()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Tema değiştirme
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('settings.logout'.tr()),
            onTap: () async {
              final authService = ref.read(authServiceProvider);
              await authService.logout();
              // ignore: use_build_context_synchronously
              context.go('/auth');
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const LanguageSelectorDialog(),
    );
  }
}
