import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../widgets/auth_form.dart';
import '../widgets/error_dialog.dart';

/// Registration screen for new user account creation
///
/// This screen provides:
/// - Email and password input fields with validation
/// - Password confirmation field
/// - Registration functionality using AuthService
/// - Loading state management
/// - Error handling and display
/// - Navigation back to login screen
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo/title
                  const Icon(
                    Icons.person_add_outlined,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Hesap Oluştur',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Yeni hesabınızı oluşturun',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Registration form
                  RegisterForm(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    passwordConfirmController: _passwordConfirmController,
                    isLoading: _isLoading,
                    onSubmit: _handleRegister,
                  ),

                  const SizedBox(height: 24),

                  // Navigation to login screen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Zaten hesabınız var mı? ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _navigateToLogin,
                        child: const Text(
                          'Giriş Yap',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Handles the registration process
  Future<void> _handleRegister() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // Get auth service and attempt registration
      final authService = ref.read(authServiceProvider);
      await authService.register(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Registration successful - navigation will be handled by AuthGate
      // Show success message
      if (mounted) {
        context.showSuccessSnackBar('Kayıt başarılı! Hoş geldiniz!');
      }
    } catch (error) {
      // Handle registration error
      if (mounted) {
        await context.showAuthError(error);
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Navigates back to the login screen
  void _navigateToLogin() {
    Navigator.of(context).pop();
  }
}