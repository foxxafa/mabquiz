import 'package:flutter/material.dart';
import '../../core/theme/theme.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ButtonType type;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.icon,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: _getGradient(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _getShadowColor(),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isLoading ? null : widget.onPressed,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null && !widget.isLoading) ...[
                          Icon(
                            widget.icon,
                            color: _getTextColor(),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (widget.isLoading)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getTextColor(),
                              ),
                            ),
                          )
                        else
                          Text(
                            widget.text,
                            style: AppTextStyles.buttonText.copyWith(
                              color: _getTextColor(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  LinearGradient _getGradient() {
    switch (widget.type) {
      case ButtonType.primary:
        return const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case ButtonType.secondary:
        return const LinearGradient(
          colors: [AppColors.secondary, Color(0xFF0E8FCC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case ButtonType.outline:
        return const LinearGradient(
          colors: [Colors.transparent, Colors.transparent],
        );
    }
  }

  Color _getShadowColor() {
    switch (widget.type) {
      case ButtonType.primary:
        return AppColors.primary.withValues(alpha: 0.3);
      case ButtonType.secondary:
        return AppColors.secondary.withValues(alpha: 0.3);
      case ButtonType.outline:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    switch (widget.type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        return Colors.white;
      case ButtonType.outline:
        return AppColors.primary;
    }
  }
}

enum ButtonType {
  primary,
  secondary,
  outline,
}
