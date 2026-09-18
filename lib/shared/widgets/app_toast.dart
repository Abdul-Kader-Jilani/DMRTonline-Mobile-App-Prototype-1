import 'dart:async';
import 'package:flutter/material.dart';

/// 1:1 Floating Toast Notification replicating `.toast` from Web Prototype/index.html
class AppToast {
  static OverlayEntry? _currentEntry;

  static const Map<String, String> _shortMessages = {
    'Finish your active riding trip first to unlock this card.': 'Complete current trip first.',
    'Maximum of 5 tickets allowed per transaction.': 'Maximum 5 tickets allowed.',
    'Please select both Origin and Destination stations.': 'Select origin and destination.',
    'Origin and Destination cannot be the same station.': 'Origin and destination cannot match.',
    'Profile information saved successfully!': 'Profile saved.',
    'Profile photo cropped & saved!': 'Profile photo saved.',
    'Scan Successful! Entry gate opened.': 'Entry scan successful.',
    'Scan Successful! QR code regenerated.': 'QR regenerated.',
    'Scan Successful! Exit gate opened. Trip Completed.': 'Trip completed.',
    'No active or available tickets to scan. Please buy a ticket first.': 'No active tickets to scan.',
  };

  /// Show floating pill toast at the bottom of the screen
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(milliseconds: 2500),
  }) {
    dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final displayMessage = _shortMessages[message] ?? message;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: displayMessage,
        isError: isError,
        duration: duration,
        onDismissed: () {
          if (_currentEntry == entry) {
            _currentEntry?.remove();
            _currentEntry = null;
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Immediately dismiss any active toast overlay
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final Duration duration;
  final VoidCallback onDismissed;

  const _ToastWidget({
    required this.message,
    required this.isError,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(_fadeAnimation);

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onDismissed();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 24,
      right: 24,
      bottom: 84 + bottomSafe, // Floating above bottom nav bar
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xF2181C1A), // rgba(24, 28, 26, 0.95)
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: widget.isError
                        ? const Color(0x66BA1A1A)
                        : const Color(0x339EF3D8),
                    width: 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isError ? Icons.error_outline : Icons.check_circle,
                      color: widget.isError
                          ? const Color(0xFFFF897D)
                          : const Color(0xFF9EF3D8),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
