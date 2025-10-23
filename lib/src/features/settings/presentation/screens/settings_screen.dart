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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
          
          return Column(
            children: [
              // Ana sayfadaki gibi navigation bar
              SafeArea(
                bottom: false,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, 
                    vertical: isSmallScreen ? 10 : 12
                  ),
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
                          fontSize: isSmallScreen ? 20 : 24,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.settings,
                          color: Colors.white,
                          size: isSmallScreen ? 22 : 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // İçerik
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      
                      // Tema Bölümü
                      _buildSectionHeader('Görünüm', Icons.palette, AppColors.accent, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      _buildThemeCards(context, ref, themeMode, isSmallScreen),

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Dil Bölümü
                      _buildSectionHeader('Dil ve Bölge', Icons.language, AppColors.success, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      _buildLanguageCard(context, currentLanguage, theme, isSmallScreen),

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Hesap Bölümü
                      _buildSectionHeader('Hesap', Icons.person, AppColors.secondary, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      _buildLogoutCard(context, ref, theme, isSmallScreen),
                      
                      SizedBox(height: isSmallScreen ? 4 : 6),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color themeColor, bool isSmallScreen) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeColor.withValues(alpha: 0.2),
                themeColor.withValues(alpha: 0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
            border: Border.all(
              color: themeColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.15),
                offset: const Offset(0, 3),
                blurRadius: 6,
                spreadRadius: -1,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: themeColor,
            size: isSmallScreen ? 20 : 24,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Text(
          title,
          style: AppTextStyles.h4.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeCards(BuildContext context, WidgetRef ref, AppThemeMode currentTheme, bool isSmallScreen) {
    return Column(
      children: [
        _buildSettingsCard(
          context: context,
          title: 'Açık Tema',
          subtitle: 'Aydınlık ve temiz görünüm',
          icon: Icons.light_mode_outlined,
          isSelected: currentTheme == AppThemeMode.light,
          color: AppColors.accent,
          onTap: () => ref.read(themeModeNotifierProvider.notifier).setLightTheme(),
          isSmallScreen: isSmallScreen,
        ),
        SizedBox(height: isSmallScreen ? 6 : 8),
        _buildSettingsCard(
          context: context,
          title: 'Koyu Tema',
          subtitle: 'Göz dostu karanlık mod',
          icon: Icons.dark_mode_outlined,
          isSelected: currentTheme == AppThemeMode.dark,
          color: AppColors.accent,
          onTap: () => ref.read(themeModeNotifierProvider.notifier).setDarkTheme(),
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildLanguageCard(BuildContext context, currentLanguage, ThemeData theme, bool isSmallScreen) {
    return _buildSettingsCard(
      context: context,
      title: 'settings.language'.tr(),
      subtitle: currentLanguage.name,
      icon: Icons.translate,
      isSelected: false,
      color: AppColors.success,
      onTap: () => _showLanguageDialog(context),
      showArrow: true,
      isSmallScreen: isSmallScreen,
    );
  }

  Widget _buildLogoutCard(BuildContext context, WidgetRef ref, ThemeData theme, bool isSmallScreen) {
    return _buildSettingsCard(
      context: context,
      title: 'settings.logout'.tr(),
      subtitle: 'Hesabınızdan çıkış yapın',
      icon: Icons.logout_outlined,
      isSelected: false,
      color: AppColors.secondary,
      onTap: () => _showLogoutDialog(context, ref),
      isDangerous: true,
      isSmallScreen: isSmallScreen,
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
    required bool isSmallScreen,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          border: Border.all(
            color: isSelected 
                ? color 
                : (isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isSmallScreen ? 44 : 52,
              height: isSmallScreen ? 44 : 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected 
                      ? [color, color.withValues(alpha: 0.8)]
                      : [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                border: Border.all(
                  color: color.withValues(alpha: isSelected ? 1.0 : 0.3),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? Colors.white
                    : color,
                size: isSmallScreen ? 22 : 26,
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark 
                          ? const Color(0xFFB0B0B0) 
                          : const Color(0xFF666666),
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: isSmallScreen ? 20 : 24,
                height: isSmallScreen ? 20 : 24,
                decoration: BoxDecoration(
                  color: const Color(0xFF58CC02), // Yeşil başarı rengi
                  borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: isSmallScreen ? 12 : 16,
                ),
              )
            else if (showArrow)
              Icon(
                Icons.arrow_forward_ios,
                color: isDark ? const Color(0xFF888888) : Colors.grey[600],
                size: isSmallScreen ? 14 : 16,
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
