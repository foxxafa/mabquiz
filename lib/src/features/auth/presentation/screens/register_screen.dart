import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mabquiz/src/features/auth/application/providers.dart';
import 'package:mabquiz/src/features/auth/presentation/utils/error_handler.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;

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
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
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

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _slideController.forward();
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _shimmerController.dispose();
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
                      SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                      _buildHeader(context),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.04),
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
    final iconSize = screenWidth * 0.18;
    
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
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: iconSize * 0.5,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.025),
        Text(
          'Hesap Oluştur',
          style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.065,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Text(
            'Maceraya katılmak için bilgileri doldur',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
                  fontSize: screenWidth * 0.038,
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
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Ad',
                    prefixIcon: const Icon(Icons.person_outline),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.018,
                    ),
                  ),
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      value!.isEmpty ? 'Ad boş olamaz' : null,
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: TextFormField(
                  controller: _surnameController,
                  decoration: InputDecoration(
                    labelText: 'Soyad',
                    prefixIcon: const Icon(Icons.person_outline),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.018,
                    ),
                  ),
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      value!.isEmpty ? 'Soyad boş olamaz' : null,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.022),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Kullanıcı Adı',
              prefixIcon: const Icon(Icons.alternate_email),
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.018,
              ),
            ),
            style: TextStyle(fontSize: screenWidth * 0.04),
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kullanıcı adı boş olamaz';
              }
              if (value.length < 3) {
                return 'Kullanıcı adı en az 3 karakter olmalıdır';
              }
              return null;
            },
          ),
          SizedBox(height: screenHeight * 0.022),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen e-posta adresinizi girin';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Lütfen geçerli bir e-posta adresi girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Şifre',
              prefixIcon: Icon(Icons.lock_outlined),
            ),
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Lütfen şifrenizi girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _passwordConfirmController,
            decoration: const InputDecoration(
              labelText: 'Şifre Tekrar',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Şifreler eşleşmiyor';
              }
              return null;
            },
            onFieldSubmitted: (_) => _handleRegister(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.primary,
                      ],
                      stops: [0.0, 0.5, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                        offset: const Offset(0, 8),
                        blurRadius: 32,
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                        offset: const Offset(0, 0),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        offset: Offset(_shimmerAnimation.value * 50, 0),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        stops: [
                          (_shimmerAnimation.value + 2.0) / 4.0 - 0.3,
                          (_shimmerAnimation.value + 2.0) / 4.0,
                          (_shimmerAnimation.value + 2.0) / 4.0 + 0.3,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(
                              'Kayıt Ol',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildDivider(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _handleGoogleSignUp,
              icon: SizedBox(
                width: 20,
                height: 20,
                child: SvgPicture.asset('assets/icons/google.svg'),
              ),
              label: const Text('Google ile Kayıt Ol'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Zaten hesabın var mı?"),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Giriş Yap'),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('VEYA'),
        ),
        Expanded(child: Divider()),
      ],
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      ref.read(authLoadingProvider.notifier).state = true;
      ref.read(authErrorProvider.notifier).state = null;

      final authService = ref.read(authServiceProvider);
      await authService.register(
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(), // Username field eklendi
        password: _passwordController.text,
        firstName: _nameController.text.trim(),
        lastName: _surnameController.text.trim(),
        department: 'general',
      );
      // Registration successful - show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Kayıt başarılı! Otomatik giriş yapılıyor...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
      // On successful registration, AuthGate will handle navigation.
      
      // TODO: Otomatik giriş için - şimdilik yorum satırında
      // await Future.delayed(Duration(seconds: 1));
      // context.go('/login'); // Veya AuthGate navigation'ı ile otomatik giriş
      
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorHandler.getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(authLoadingProvider.notifier).state = false;
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google ile kayıt olma yakında eklenecek!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
