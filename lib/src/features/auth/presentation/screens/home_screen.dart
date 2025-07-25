import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../quiz/presentation/screens/quiz_screen.dart';
import '../../application/providers.dart';
import '../widgets/error_dialog.dart';

/// Modern dashboard with Duolingo-style design
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFF667eea),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeCard(currentUser),
                          const SizedBox(height: 20),
                          _buildStatsCards(),
                          const SizedBox(height: 20),
                          _buildQuickActions(),
                          const SizedBox(height: 20),
                          _buildRecentProgress(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Text(
            'MAB Quiz',
            style: AppTextStyles.h2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
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
                : const Icon(
                    Icons.logout,
                    color: Colors.white,
                  ),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(currentUser) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş Geldin!',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      currentUser?.email ?? 'Kullanıcı',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: currentUser?.emailVerified == true
                      ? Colors.green
                      : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  currentUser?.emailVerified == true
                      ? 'Email Doğrulandı'
                      : 'Email Doğrulanmadı',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: currentUser?.emailVerified == true
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İstatistikler',
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.quiz,
                title: 'Toplam Soru',
                value: '0',
                color: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.check_circle,
                title: 'Doğru Cevap',
                value: '0',
                color: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.trending_up,
                title: 'Başarı Oranı',
                value: '0%',
                color: const Color(0xFFFF9800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer,
                title: 'Ortalama Süre',
                value: '0s',
                color: const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı Başlat',
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.play_arrow,
                title: 'Quiz Başlat',
                subtitle: 'Yeni bir quiz oturumu başlat',
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuizScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.analytics,
                title: 'İlerlemeni Gör',
                subtitle: 'Detaylı analiz ve rapor',
                gradient: const LinearGradient(
                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                ),
                onTap: () {
                  // TODO: Analytics ekranına yönlendir
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Analiz özelliği yakında eklenecek!'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, 8),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProgress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son Aktiviteler',
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressItem(
            icon: Icons.school,
            title: 'Matematik - Temel',
            subtitle: 'Henüz başlanmadı',
            progress: 0.0,
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            icon: Icons.language,
            title: 'Türkçe - Gramer',
            subtitle: 'Henüz başlanmadı',
            progress: 0.0,
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            icon: Icons.science,
            title: 'Fen Bilgisi',
            subtitle: 'Henüz başlanmadı',
            progress: 0.0,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required double progress,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ],
          ),
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSignOut() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoggingOut = true);

      final authService = ref.read(authServiceProvider);
      await authService.logout();

      // AuthGate will automatically redirect to login screen
    } catch (e) {
      if (mounted) {
        await AuthErrorDialog.showAuthError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }
}
