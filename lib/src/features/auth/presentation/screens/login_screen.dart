import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../application/providers.dart';
import '../utils/form_validators.dart';
import '../utils/error_handler.dart';
import 'register_screen.dart';

/// Login screen for user authentication
///
/// This screen provides:
/// - Email and password input fields with validation
/// - Login functionality using AuthService
/// - Loading state management
/// - Error handling and display
/// - Navigation to registration screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top - 48,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Logo ve Başlık
                    _buildHeader(),
                    const SizedBox(height: 48),
                    // Form
                    Expanded(
                      child: _buildForm(isLoading),
                    ),
                    // Alt kısım
                    _buildFooter(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                offset: const Offset(0, 8),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.quiz,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        // Başlık
        Text(
          'Hoş Geldin!',
          style: AppTextStyles.h1.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Öğrenmeye devam etmek için giriş yap',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          CustomTextField(
            label: 'E-posta',
            hint: 'ornek@email.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.next,
            validator: AuthFormValidators.validateEmail,
          ),
          const SizedBox(height: 20),

          // Password Field
          CustomTextField(
            label: 'Şifre',
            hint: 'Şifrenizi girin',
            controller: _passwordController,
            obscureText: true,
            prefixIcon: Icons.lock_outlined,
            textInputAction: TextInputAction.done,
            validator: AuthFormValidators.validatePassword,
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 12),

          // Şifremi Unuttum
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Şifre sıfırlama
              },
              child: Text(
                'Şifremi Unuttum',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Login Button
          CustomButton(
            text: 'Giriş Yap',
            onPressed: isLoading ? null : _handleLogin,
            isLoading: isLoading,
            type: ButtonType.primary,
          ),
          const SizedBox(height: 16),

          // Google ile Giriş
          CustomButton(
            text: 'Google ile Giriş Yap',
            onPressed: isLoading ? null : _handleGoogleLogin,
            type: ButtonType.outline,
            icon: Icons.g_mobiledata,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Hesabın yok mu? ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RegisterScreen(),
              ),
            );
          },
          child: Text(
            'Kayıt Ol',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      ref.read(authLoadingProvider.notifier).state = true;
      ref.read(authErrorProvider.notifier).state = null;

      final authService = ref.read(authServiceProvider);
      await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Login başarılı - AuthGate otomatik yönlendirecek
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();

      if (mounted) {
        await AuthErrorHandler.handleError(
          context,
          e,
        );
      }
    } finally {
      if (mounted) {
        ref.read(authLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    // TODO: Google Sign-In implementasyonu
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google ile giriş yakında eklenecek'),
      ),
    );
  }
}
