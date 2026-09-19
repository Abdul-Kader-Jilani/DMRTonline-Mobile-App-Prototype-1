import 'dart:ui';
import 'package:flutter/material.dart';

/// 1:1 Strict Recreation of #no-internet-overlay from Web Prototype/index.html
class NoInternetDialog extends StatelessWidget {
  final VoidCallback onDismiss;

  const NoInternetDialog({
    super.key,
    required this.onDismiss,
  });

  /// Displays the No Internet Connection dialog modal with blurred backdrop
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: const Color(0x99000000), // rgba(0, 0, 0, 0.6)
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: NoInternetDialog(
          onDismiss: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // var(--radius-2xl)
            border: Border.all(
              color: const Color(0x73BEC9C3), // var(--color-outline-variant)
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Red Circle Icon Container (wifi_off)
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2), // Soft red background
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.wifi_off,
                  size: 36,
                  color: Color(0xFFBA1A1A), // var(--color-error)
                ),
              ),
              const SizedBox(height: 16),

              // 2. Title: "No Internet Connection" (.confirm-title)
              const Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF181C1A), // var(--color-on-surface)
                ),
              ),
              const SizedBox(height: 8),

              // 3. Message (.confirm-text)
              const Text(
                'You are currently offline. Tickets cannot be purchased without an active internet connection. Please connect to the internet and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3E4945), // var(--color-on-surface-variant)
                ),
              ),
              const SizedBox(height: 24),

              // 4. "Understood" Button (.btn-save)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005140), // var(--color-primary)
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999), // pill button
                    ),
                  ),
                  child: const Text(
                    'Understood',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
