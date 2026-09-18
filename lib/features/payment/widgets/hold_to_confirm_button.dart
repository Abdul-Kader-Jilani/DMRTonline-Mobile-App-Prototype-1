import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 1:1 Strict Recreation of `.hold-purchase-section` and authentic hold physics
class HoldToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirmed;

  const HoldToConfirmButton({
    super.key,
    required this.onConfirmed,
  });

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isHolding = false;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPressStart() {
    if (_isConfirmed) return;
    setState(() {
      _isHolding = true;
    });
    HapticFeedback.lightImpact();
    _controller.forward(from: 0.0);
  }

  void _onPressEnd() {
    if (_isConfirmed) return;
    setState(() {
      _isHolding = false;
    });
    _controller.animateBack(
      0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _handleComplete() {
    setState(() {
      _isHolding = false;
      _isConfirmed = true;
    });
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        widget.onConfirmed();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _onPressStart(),
      onPointerUp: (_) => _onPressEnd(),
      onPointerCancel: (_) => _onPressEnd(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Center Interactive Button (.hold-logo-wrapper)
            SizedBox(
              width: 74,
              height: 74,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Circular Progress Ring (r=33)
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(74, 74),
                        painter: _HoldProgressPainter(
                          progress: _controller.value,
                          isConfirmed: _isConfirmed,
                        ),
                      );
                    },
                  ),

                  // Inner Logo Circle Button (.hold-logo-btn)
                  AnimatedScale(
                    scale: _isConfirmed
                        ? 1.06
                        : (_isHolding ? 0.94 : 1.0),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _isConfirmed
                            ? const Color(0xFF006B56)
                            : const Color(0xFF005140),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _isConfirmed
                                ? const Color(0x66006B56)
                                : const Color(0x4D005140),
                            blurRadius: _isConfirmed ? 14 : 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _isConfirmed
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 32,
                            )
                          : Image.asset(
                              'assets/dmrt/logo.png',
                              width: 34,
                              height: 34,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.train,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 2. State Label (.hold-purchase-label)
            Text(
              _isConfirmed
                  ? 'Confirmed!'
                  : (_isHolding ? 'Holding...' : 'Hold to purchase'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _isConfirmed
                    ? const Color(0xFF006B56)
                    : const Color(0xFF005140),
              ),
            ),
            const SizedBox(height: 2),

            // 3. Subtext (.hold-purchase-subtext)
            Text(
              _isConfirmed
                  ? 'Ticket purchased successfully'
                  : 'Press and hold for 1 second to confirm',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6E7A75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldProgressPainter extends CustomPainter {
  final double progress;
  final bool isConfirmed;

  const _HoldProgressPainter({
    required this.progress,
    required this.isConfirmed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 33.0;
    const strokeWidth = 3.5;

    // Track circle
    final trackPaint = Paint()
      ..color = const Color(0x4DBEC9C3)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    if (progress > 0.0 || isConfirmed) {
      final sweepAngle = (isConfirmed ? 1.0 : progress) * 2 * math.pi;
      final progressPaint = Paint()
        ..color = isConfirmed
            ? const Color(0xFF006B56)
            : const Color(0xFF005140)
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start at top (12 o'clock)
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HoldProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isConfirmed != isConfirmed;
  }
}
