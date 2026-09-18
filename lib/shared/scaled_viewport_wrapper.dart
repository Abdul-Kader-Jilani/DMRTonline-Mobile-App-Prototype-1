import 'package:flutter/material.dart';

/// Proportional Viewport Scaling Wrapper (Smart Scaled Layout)
///
/// Locks the UI coordinate system to a fixed 360px wide reference canvas
/// matching Web Prototype/index.html adjustViewport() logic:
/// `scale = min(screenWidth, 480) / 360.0`
///
/// Ensures all visual elements, ticket card punch notches, S-curve wave masks,
/// typography, and button coordinates stay 100% locked in place without horizontal drift.
class ScaledViewportWrapper extends StatelessWidget {
  final double baseWidth;
  final double maxTabletWidth;
  final Widget child;

  const ScaledViewportWrapper({
    super.key,
    this.baseWidth = 360.0,
    this.maxTabletWidth = 480.0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        // Clamp tablet width to prevent oversized elements on large displays
        final activeWidth = screenWidth > maxTabletWidth ? maxTabletWidth : screenWidth;
        final scale = activeWidth / baseWidth;

        // Corresponding height in 360px coordinate space
        final baseHeight = constraints.maxHeight / scale;

        final mq = MediaQuery.maybeOf(context) ?? const MediaQueryData();
        final scaledMq = mq.copyWith(
          size: Size(baseWidth, baseHeight),
          padding: mq.padding / scale,
          viewPadding: mq.viewPadding / scale,
          viewInsets: mq.viewInsets / scale,
          devicePixelRatio: mq.devicePixelRatio * scale,
        );

        return Center(
          child: SizedBox(
            width: activeWidth,
            height: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: baseWidth,
                height: baseHeight,
                child: MediaQuery(
                  data: scaledMq,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
