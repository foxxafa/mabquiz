import 'package:flutter/material.dart';

/// A loading overlay widget that can be shown over other content
///
/// This widget displays a semi-transparent overlay with a loading indicator
/// and optional message. It's designed to be used during async operations
/// to prevent user interaction and provide visual feedback.
class LoadingOverlay extends StatelessWidget {
  /// Whether the overlay should be visible
  final bool isLoading;

  /// The child widget to display behind the overlay
  final Widget child;

  /// Optional message to display below the loading indicator
  final String? message;

  /// Color of the overlay background
  final Color overlayColor;

  /// Color of the loading indicator
  final Color? indicatorColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.overlayColor = const Color(0x80000000), // Semi-transparent black
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: overlayColor,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: indicatorColor != null
                            ? AlwaysStoppedAnimation<Color>(indicatorColor!)
                            : null,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          message!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A simple loading overlay that covers the entire screen
///
/// This is a convenience widget for showing a full-screen loading overlay
/// with a default message.
class FullScreenLoadingOverlay extends StatelessWidget {
  /// Optional message to display below the loading indicator
  final String message;

  const FullScreenLoadingOverlay({
    super.key,
    this.message = 'Yükleniyor...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x80000000),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}