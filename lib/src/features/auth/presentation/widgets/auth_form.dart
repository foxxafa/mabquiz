import 'package:flutter/material.dart';
import '../utils/form_validators.dart';

/// Base widget for authentication forms
///
/// This widget provides common form fields and validation logic
/// for email and password inputs used in login and registration screens.
class AuthForm extends StatefulWidget {
  /// Form key for validation
  final GlobalKey<FormState> formKey;

  /// Controller for email input
  final TextEditingController emailController;

  /// Controller for password input
  final TextEditingController passwordController;

  /// Controller for password confirmation (optional, used in registration)
  final TextEditingController? passwordConfirmController;

  /// Whether to show password confirmation field
  final bool showPasswordConfirmation;

  /// Whether the form is in loading state
  final bool isLoading;

  /// Callback when form is submitted
  final VoidCallback onSubmit;

  /// Text for the submit button
  final String submitButtonText;

  /// Optional additional form fields to display above the submit button
  final List<Widget> additionalFields;

  const AuthForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    this.passwordConfirmController,
    this.showPasswordConfirmation = false,
    required this.isLoading,
    required this.onSubmit,
    required this.submitButtonText,
    this.additionalFields = const [],
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email field
          TextFormField(
            controller: widget.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !widget.isLoading,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'ornek@email.com',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            validator: _validateEmail,
          ),

          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: widget.passwordController,
            obscureText: _obscurePassword,
            textInputAction: widget.showPasswordConfirmation
                ? TextInputAction.next
                : TextInputAction.done,
            enabled: !widget.isLoading,
            decoration: InputDecoration(
              labelText: 'Şifre',
              hintText: 'Şifrenizi girin',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
            validator: _validatePassword,
            onFieldSubmitted: widget.showPasswordConfirmation
                ? null
                : (_) => _handleSubmit(),
          ),

          // Password confirmation field (if needed)
          if (widget.showPasswordConfirmation) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: widget.passwordConfirmController,
              obscureText: _obscurePasswordConfirm,
              textInputAction: TextInputAction.done,
              enabled: !widget.isLoading,
              decoration: InputDecoration(
                labelText: 'Şifre Tekrarı',
                hintText: 'Şifrenizi tekrar girin',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePasswordConfirm
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePasswordConfirm = !_obscurePasswordConfirm;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              validator: _validatePasswordConfirmation,
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
          ],

          // Additional fields
          ...widget.additionalFields.map((field) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: field,
          )),

          const SizedBox(height: 24),

          // Submit button
          ElevatedButton(
            onPressed: widget.isLoading ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.submitButtonText,
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (widget.formKey.currentState?.validate() ?? false) {
      widget.onSubmit();
    }
  }

  String? _validateEmail(String? value) {
    return AuthFormValidators.validateEmail(value);
  }

  String? _validatePassword(String? value) {
    return AuthFormValidators.validatePassword(value);
  }

  String? _validatePasswordConfirmation(String? value) {
    if (!widget.showPasswordConfirmation) return null;
    return AuthFormValidators.validatePasswordConfirmation(value, widget.passwordController.text);
  }
}

/// A simple email/password form for login
class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AuthForm(
      formKey: formKey,
      emailController: emailController,
      passwordController: passwordController,
      isLoading: isLoading,
      onSubmit: onSubmit,
      submitButtonText: 'Giriş Yap',
    );
  }
}

/// A form with email, password, and password confirmation for registration
class RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController passwordConfirmController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const RegisterForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.passwordConfirmController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AuthForm(
      formKey: formKey,
      emailController: emailController,
      passwordController: passwordController,
      passwordConfirmController: passwordConfirmController,
      showPasswordConfirmation: true,
      isLoading: isLoading,
      onSubmit: onSubmit,
      submitButtonText: 'Kayıt Ol',
    );
  }
}