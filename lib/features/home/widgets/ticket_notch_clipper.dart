import 'package:flutter/material.dart';

/// Clips semi-circular punch notches (r=12px) on the left and right edges
/// with 32px rounded card corners matching Web Prototype/index.html
class TicketNotchClipper extends CustomClipper<Path> {
  final double notchRadius;
  final double notchY;

  const TicketNotchClipper({
    this.notchRadius = 12.0,
    required this.notchY,
  });

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    const cornerRadius = 32.0;

    final path = Path();

    // Top-left corner
    path.moveTo(0, cornerRadius);
    path.arcToPoint(
      const Offset(cornerRadius, 0),
      radius: const Radius.circular(cornerRadius),
    );

    // Top edge
    path.lineTo(w - cornerRadius, 0);

    // Top-right corner
    path.arcToPoint(
      Offset(w, cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    // Right edge down to notch
    path.lineTo(w, notchY - notchRadius);

    // Right inward semi-circular notch
    path.arcToPoint(
      Offset(w, notchY + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Right edge down to bottom-right corner
    path.lineTo(w, h - cornerRadius);
    path.arcToPoint(
      Offset(w - cornerRadius, h),
      radius: const Radius.circular(cornerRadius),
    );

    // Bottom edge
    path.lineTo(cornerRadius, h);

    // Bottom-left corner
    path.arcToPoint(
      Offset(0, h - cornerRadius),
      radius: const Radius.circular(cornerRadius),
    );

    // Left edge up to notch
    path.lineTo(0, notchY + notchRadius);

    // Left inward semi-circular notch
    path.arcToPoint(
      Offset(0, notchY - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );

    // Close path
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant TicketNotchClipper oldClipper) =>
      oldClipper.notchRadius != notchRadius || oldClipper.notchY != notchY;
}
