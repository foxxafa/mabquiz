import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: theme.colorScheme.background,
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
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: const Text('Çıkış Yap'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              // ignore: use_build_context_synchronously
              context.go('/auth');
            },
          ),
        ],
      ),
    );
  }
}
