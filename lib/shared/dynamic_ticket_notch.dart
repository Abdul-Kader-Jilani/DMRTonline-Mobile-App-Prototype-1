import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_gradients.dart';

/// 1:1 Strict Recreation of dynamic punch hole notches from Web Prototype/index.html
/// Automatically calculates the exact gradient color at its vertical screen position (Y coordinate)
/// using AppGradients.getGradientColorAt(pct) so that punch holes blend 100% seamlessly
/// with the background gradient across all screens, modals, and scroll positions.
class DynamicTicketNotchCutout extends StatefulWidget {
  final bool isLeft;
  final Color? fallbackColor;

  const DynamicTicketNotchCutout({
    super.key,
    required this.isLeft,
    this.fallbackColor,
  });

  @override
  State<DynamicTicketNotchCutout> createState() => _DynamicTicketNotchCutoutState();
}

class _DynamicTicketNotchCutoutState extends State<DynamicTicketNotchCutout> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: const Size(24, 24),
          painter: _DynamicTicketNotchPainter(
            isLeft: widget.isLeft,
            fallbackColor: widget.fallbackColor,
            context: context,
          ),
        );
      },
    );
  }
}

class _DynamicTicketNotchPainter extends CustomPainter {
  final bool isLeft;
  final Color? fallbackColor;
  final BuildContext context;

  static const Color _borderColor = Color(0x4DBEC9C3); // rgba(190, 201, 195, 0.3)

  const _DynamicTicketNotchPainter({
    required this.isLeft,
    required this.fallbackColor,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Color notchBgColor = fallbackColor ?? const Color(0xFF9FD1C6);
    if (fallbackColor == null) {
      try {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.hasSize) {
          final globalOffset = renderBox.localToGlobal(Offset.zero);
          final screenHeight = MediaQuery.of(context).size.height;
          if (screenHeight > 0) {
            final centerY = globalOffset.dy + (size.height / 2);
            final pct = (centerY / screenHeight * 100.0).clamp(0.0, 100.0);
            notchBgColor = AppGradients.getGradientColorAt(pct);
          }
        }
      } catch (_) {
        notchBgColor = fallbackColor ?? const Color(0xFF9FD1C6);
      }
    }

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Fill Circle with dynamically sampled page background color
    final fillPaint = Paint()
      ..color = notchBgColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, fillPaint);

    // 2. Inner Shadow on the semicircular arc entering the card (inset 3px / -3px)
    // Matches Web Prototype: box-shadow: inset -3px 0 4px -2px rgba(0, 0, 0, 0.15)
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        center: isLeft ? const Alignment(0.6, 0.0) : const Alignment(-0.6, 0.0),
        radius: 0.9,
        colors: const [
          Colors.transparent,
          Color(0x26000000), // rgba(0, 0, 0, 0.15)
        ],
        stops: const [0.4, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.save();
    if (isLeft) {
      canvas.clipRect(Rect.fromLTWH(center.dx, 0, radius + 2, size.height));
    } else {
      canvas.clipRect(Rect.fromLTWH(0 - 2, 0, radius + 2, size.height));
    }
    canvas.drawCircle(center, radius, shadowPaint);
    canvas.restore();

    // 3. Inner Semicircle Border Stroke (ONLY entering the ticket card, NO outer stroke)
    final borderPaint = Paint()
      ..color = _borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final arcRect = Rect.fromCircle(center: center, radius: radius - 0.5);
    if (isLeft) {
      // Sweeps from -90 deg to +90 deg (right half facing into the ticket card)
      canvas.drawArc(arcRect, -math.pi / 2, math.pi, false, borderPaint);
    } else {
      // Sweeps from +90 deg to +270 deg (left half facing into the ticket card)
      canvas.drawArc(arcRect, math.pi / 2, math.pi, false, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DynamicTicketNotchPainter oldDelegate) {
    return true;
  }
}
