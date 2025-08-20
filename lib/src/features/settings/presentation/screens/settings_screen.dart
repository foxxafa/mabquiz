import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/application/providers.dart';
import '../../../../core/localization/localization_provider.dart';
import '../../../settings/application/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/language_selector_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentLanguage = context.currentLanguage;
    final themeMode = ref.watch(themeModeNotifierProvider);
    
    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light 
          ? AppColors.background 
          : const Color(0xFF121212),
      body: Column(
        children: [
          // Ana sayfadaki gibi navigation bar
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3a3a3a),
                    Color(0xFF2d2d2d),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'settings.title'.tr(),
                    style: AppTextStyles.h2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // İçerik
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Tema Bölümü
                  _buildSectionHeader('Görünüm', Icons.palette),
                  const SizedBox(height: 16),
                  _buildThemeCards(context, ref, themeMode),
                  
                  const SizedBox(height: 32),
                  
                  // Dil Bölümü
                  _buildSectionHeader('Dil ve Bölge', Icons.language),
                  const SizedBox(height: 16),
                  _buildLanguageCard(context, currentLanguage, theme),
                  
                  const SizedBox(height: 32),
                  
                  // Hesap Bölümü
                  _buildSectionHeader('Hesap', Icons.person),
                  const SizedBox(height: 24),
                  _buildLogoutCard(context, ref, theme),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    // Her bölüm için farklı renkler
    Color iconColor;
    Color backgroundColor;
    
    switch (title) {
      case 'Görünüm':
        iconColor = const Color(0xFF4F9CF9); // Mavi
        backgroundColor = const Color(0xFF4F9CF9).withOpacity(0.1);
        break;
      case 'Dil ve Bölge':
        iconColor = const Color(0xFF58CC02); // Yeşil
        backgroundColor = const Color(0xFF58CC02).withOpacity(0.1);
        break;
      case 'Hesap':
        iconColor = const Color(0xFFFF9600); // Turuncu
        backgroundColor = const Color(0xFFFF9600).withOpacity(0.1);
        break;
      default:
        iconColor = Colors.white;
        backgroundColor = const Color(0xFF3a3a3a);
    }
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCards(BuildContext context, WidgetRef ref, AppThemeMode currentTheme) {
    return Column(
      children: [
        _buildSettingsCard(
          context: context,
          title: 'Açık Tema',
          subtitle: 'Aydınlık ve temiz görünüm',
          icon: Icons.light_mode_outlined,
          isSelected: currentTheme == AppThemeMode.light,
          color: const Color(0xFFFFB800), // Sarı/altın
          onTap: () => ref.read(themeModeNotifierProvider.notifier).setLightTheme(),
        ),
        const SizedBox(height: 12),
        _buildSettingsCard(
          context: context,
          title: 'Koyu Tema',
          subtitle: 'Göz dostu karanlık mod',
          icon: Icons.dark_mode_outlined,
          isSelected: currentTheme == AppThemeMode.dark,
          color: const Color(0xFF64B5F6), // Açık mavi - koyu temaya daha uygun
          onTap: () => ref.read(themeModeNotifierProvider.notifier).setDarkTheme(),
        ),
      ],
    );
  }

  Widget _buildLanguageCard(BuildContext context, currentLanguage, ThemeData theme) {
    return _buildSettingsCard(
      context: context,
      title: 'settings.language'.tr(),
      subtitle: currentLanguage.name,
      icon: Icons.translate,
      isSelected: false,
      color: const Color(0xFF1CB0F6), // Mavi
      onTap: () => _showLanguageDialog(context),
      showArrow: true,
    );
  }

  Widget _buildLogoutCard(BuildContext context, WidgetRef ref, ThemeData theme) {
    return _buildSettingsCard(
      context: context,
      title: 'settings.logout'.tr(),
      subtitle: 'Hesabınızdan çıkış yapın',
      icon: Icons.logout_outlined,
      isSelected: false,
      color: const Color(0xFFFF4B4B), // Kırmızı
      onTap: () => _showLogoutDialog(context, ref),
      isDangerous: true,
    );
  }

  Widget _buildSettingsCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
    bool showArrow = false,
    bool isDangerous = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? color 
                : (isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                    ? color
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? Colors.white
                    : color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark 
                          ? const Color(0xFFB0B0B0) 
                          : const Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02), // Yeşil başarı rengi
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else if (showArrow)
              Icon(
                Icons.arrow_forward_ios,
                color: isDark ? const Color(0xFF888888) : Colors.grey[600],
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => const LanguageSelectorDialog(),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Çıkış Yap',
          style: AppTextStyles.h4.copyWith(
            color: const Color(0xFFFF4B4B), // Kırmızı
          ),
        ),
        content: Text(
          'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'İptal',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authService = ref.read(authServiceProvider);
              await authService.logout();
              // ignore: use_build_context_synchronously
              context.go('/auth');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B4B), // Kırmızı
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Çıkış Yap',
              style: AppTextStyles.buttonText.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
