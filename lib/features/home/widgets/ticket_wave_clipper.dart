import 'package:flutter/material.dart';

/// Implements the signature DMRT curved S-curve wave transition
/// corresponding to the SVG mask from Web Prototype/index.html:
/// d="M 0,0 L 100,0 L 100,50 L 50,50 C 43,50 43,100 36,100 L 0,100 Z"
class TicketWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // Start at top-left
    path.moveTo(0, 0);
    // Across top edge to top-right
    path.lineTo(w, 0);
    // Down right edge to 50% height
    path.lineTo(w, h * 0.50);
    // Horizontal inward to 50% width
    path.lineTo(w * 0.50, h * 0.50);
    // Cubic bezier S-curve: from (50%, 50%) curving to (36%, 100%)
    path.cubicTo(
      w * 0.43, h * 0.50,
      w * 0.43, h * 1.0,
      w * 0.36, h * 1.0,
    );
    // Across bottom edge to bottom-left
    path.lineTo(0, h);
    // Close back to top-left
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
