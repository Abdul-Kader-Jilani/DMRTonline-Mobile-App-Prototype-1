import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

/// 1:1 Strict Pure Recreation of `#loading-scene` from Web Prototype/index.html
///
/// Visual Specifications:
/// - Background: rgba(217, 232, 229, 0.42) (Color(0x6BD9E8E5))
/// - Backdrop Filter: blur(9px)
/// - Animation: assets/dmrt/loading.gif (clamp 86px-126px, default 96px)
/// - Text: Inter 12px / line-height 16px, FontWeight.w700, letterSpacing 0.1px, Color(0xFF005140)
/// - Transition: 180ms ease
/// - Default Delay: 1000ms (1.0s)
class LoadingSceneOverlay extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const LoadingSceneOverlay({
    super.key,
    this.message = '',
    this.onTap,
  });

  /// Runs an asynchronous action with the exact 1000ms loading scene delay from index.html
  static Future<void> runWithLoading(
    BuildContext context,
    String message,
    FutureOr<void> Function() action, {
    Duration delay = const Duration(milliseconds: 1000),
  }) async {
    BuildContext? dialogContext;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'LoadingScene',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) {
        dialogContext = ctx;
        return LoadingSceneOverlay(message: message);
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.ease),
          child: child,
        );
      },
    );

    await Future.delayed(delay);

    if (dialogContext != null && dialogContext!.mounted) {
      Navigator.of(dialogContext!).pop();
    } else if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    await action();
  }

  /// Displays the loading scene for manual demonstration (click anywhere to close)
  static void show(
    BuildContext context, {
    String message = 'Click anywhere to close',
    VoidCallback? onDismissed,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'LoadingScene',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, anim1, anim2) => LoadingSceneOverlay(
        message: message,
        onTap: () {
          Navigator.of(ctx).pop();
          if (onDismissed != null) onDismissed();
        },
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim1, curve: Curves.ease),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final animSize = (screenWidth * 0.26).clamp(86.0, 126.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap ?? () => Navigator.of(context).pop(),
      child: Material(
        color: Colors.transparent,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0x6BD9E8E5), // rgba(217, 232, 229, 0.42)
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Loading GIF animation (.loading-scene__animation)
                    Image.asset(
                      'assets/dmrt/loading.gif',
                      width: animSize,
                      height: animSize,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => SizedBox(
                        width: animSize * 0.6,
                        height: animSize * 0.6,
                        child: const CircularProgressIndicator(
                          strokeWidth: 3.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005140)),
                        ),
                      ),
                    ),

                    // Loading message text (.loading-scene__text)
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            height: 16 / 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                            color: Color(0xFF005140), // var(--color-primary)
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
