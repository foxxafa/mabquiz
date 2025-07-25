import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../widgets/error_dialog.dart';

/// Home screen for authenticated users
///
/// This screen provides:
/// - Display of current user information
/// - Sign out functionality using AuthService
/// - Error handling for logout operations
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    // Watch the current user
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Sign out button in app bar
          IconButton(
            onPressed: _isLoggingOut ? null : _handleSignOut,
            icon: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // User avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Welcome message
                      Text(
                        'Hoş Geldiniz!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // User information
                      if (currentUser != null) ...[
                        _buildUserInfoRow(
                          icon: Icons.email,
                          label: 'Email',
                          value: currentUser.email ?? 'Bilinmiyor',
                        ),
                        const SizedBox(height: 8),
                        _buildUserInfoRow(
                          icon: Icons.person,
                          label: 'Kullanıcı Adı',
                          value: currentUser.displayName ?? 'Ayarlanmamış',
                        ),
                        const SizedBox(height: 8),
                        _buildUserInfoRow(
                          icon: Icons.verified_user,
                          label: 'Email Doğrulandı',
                          value: currentUser.emailVerified ? 'Evet' : 'Hayır',
                          valueColor: currentUser.emailVerified
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ] else ...[
                        Text(
                          'Kullanıcı bilgileri yükleniyor...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Sign out button
              ElevatedButton.icon(
                onPressed: _isLoggingOut ? null : _handleSignOut,
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.logout),
                label: Text(_isLoggingOut ? 'Çıkış Yapılıyor...' : 'Çıkış Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const Spacer(),

              // App info
              Text(
                'Güvenli bir şekilde giriş yaptınız.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a user information row
  Widget _buildUserInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: valueColor != null ? FontWeight.w500 : null,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  /// Handles the sign out process
  Future<void> _handleSignOut() async {
    // Show confirmation dialog
    final shouldSignOut = await context.showConfirmation(
      title: 'Çıkış Yap',
      message: 'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
      confirmText: 'Çıkış Yap',
      cancelText: 'İptal',
    );

    if (!shouldSignOut) return;

    // Set loading state
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Get auth service and attempt logout
      final authService = ref.read(authServiceProvider);
      await authService.logout();

      // Logout successful - navigation will be handled by AuthGate
      // Show success message
      if (mounted) {
        context.showSuccessSnackBar('Başarıyla çıkış yapıldı.');
      }
    } catch (error) {
      // Handle logout error
      if (mounted) {
        await context.showAuthError(error);
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }
}