import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mabquiz/src/features/auth/application/providers.dart';
import 'package:mabquiz/src/features/auth/presentation/utils/error_handler.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
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

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                      _buildHeader(context),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                      _buildForm(isLoading),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                      _buildFooter(),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.2;
    
    return Column(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(iconSize * 0.25),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                offset: const Offset(0, 8),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(
            Icons.quiz,
            color: Colors.white,
            size: iconSize * 0.5,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.03),
        Text(
          'login.welcome_back'.tr(),
          style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.07,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          child: Text(
            'login.login_subtitle'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                  fontSize: screenWidth * 0.04,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'login.username'.tr(),
              prefixIcon: const Icon(Icons.person_outlined),
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
            ),
            style: TextStyle(fontSize: screenWidth * 0.045),
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kullanıcı adı gereklidir';
              }
              if (value.length < 3) {
                return 'Kullanıcı adı en az 3 karakter olmalıdır';
              }
              return null;
            },
          ),
          SizedBox(height: screenHeight * 0.025),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'login.password'.tr(),
              prefixIcon: const Icon(Icons.lock_outlined),
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
            ),
            style: TextStyle(fontSize: screenWidth * 0.045),
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'login.password_required'.tr();
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleLogin(),
          ),
          SizedBox(height: screenHeight * 0.015),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Şifre sıfırlama özelliği backend entegrasyonu sonrası eklenecek
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Şifre sıfırlama özelliği yakında eklenecek'),
                  ),
                );
              },
              child: Text(
                'login.forgot_password'.tr(),
                style: TextStyle(fontSize: screenWidth * 0.035),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.065,
            child: ElevatedButton(
              onPressed: isLoading ? null : _handleLogin,
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'login.login_button'.tr(),
                      style: TextStyle(fontSize: screenWidth * 0.045),
                    ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.065,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _handleGoogleLogin,
              icon: SizedBox(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                child: SvgPicture.asset('assets/icons/google.svg'),
              ),
              label: Text(
                'Google ile Giriş Yap',
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          // Hızlı giriş butonu
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.065,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _handleQuickLogin,
              icon: Icon(Icons.flash_on, size: screenWidth * 0.05),
              label: Text(
                'Hızlı Giriş (Test)',
                style: TextStyle(fontSize: screenWidth * 0.04),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F9CF9),
                foregroundColor: Colors.white,
                side: BorderSide(color: const Color(0xFF4F9CF9).withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Hesabın yok mu?",
          style: TextStyle(fontSize: screenWidth * 0.04),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          child: Text(
            'Kayıt Ol',
            style: TextStyle(fontSize: screenWidth * 0.04),
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
        _usernameController.text.trim(),
        _passwordController.text,
      );
      
      print('🎉 Login successful! Navigating to home...');
      
      // Navigate directly to home after successful login
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();

      if (mounted) {
        // Debug için detaylı hata mesajı
        String errorMessage = AuthErrorHandler.getErrorMessage(e);
        String debugInfo = 'Hata detayı: ${e.toString()}';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                const SizedBox(height: 4),
                Text(
                  debugInfo,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(authLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _handleQuickLogin() async {
    try {
      ref.read(authLoadingProvider.notifier).state = true;
      ref.read(authErrorProvider.notifier).state = null;

      // Test kullanıcısı ile giriş yap
      final authService = ref.read(authServiceProvider);
      await authService.login('testuser', '123');
      
      print('🎉 Quick login successful! Navigating to home...');
      
      // Navigate directly to home after successful login
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Hızlı giriş başarısız oldu';
        String debugInfo = 'Hata detayı: ${e.toString()}';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                const SizedBox(height: 4),
                Text(
                  debugInfo,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(authLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google ile giriş yakında eklenecek'),
      ),
    );
  }
}
