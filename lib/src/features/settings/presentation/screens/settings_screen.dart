import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/application/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
                backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: Icon(Icons.language, color: theme.colorScheme.primary),
            title: const Text('Dil'),
            subtitle: const Text('Türkçe'),
            onTap: () {
              // Dil değiştirme dialoğu
            },
          ),
          ListTile(
            leading: Icon(Icons.color_lens, color: theme.colorScheme.primary),
            title: const Text('Tema'),
            subtitle: const Text('Karanlık Tema'),
            onTap: () {
              // Tema değiştirme
            },
          ),
          ListTile(
            leading: Icon(Icons.api, color: theme.colorScheme.secondary),
            title: const Text('API Test'),
            subtitle: const Text('Backend bağlantısını test et'),
            onTap: () {
              context.go('/api-test');
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: const Text('Çıkış Yap'),
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
}
