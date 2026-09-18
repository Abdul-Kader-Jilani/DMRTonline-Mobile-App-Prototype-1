import 'package:flutter/material.dart';
import 'dashed_perforation_line.dart';

/// 1:1 Strict Recreation of Route Connector from Web Prototype/index.html
/// Handles static connector (available/locked), animated journey (riding),
/// and stopped arrow at destination (exit gate).
class AnimatedRouteConnector extends StatefulWidget {
  final bool isRiding;
  final bool exitQrActive;

  const AnimatedRouteConnector({
    super.key,
    required this.isRiding,
    this.exitQrActive = false,
  });

  @override
  State<AnimatedRouteConnector> createState() => _AnimatedRouteConnectorState();
}

class _AnimatedRouteConnectorState extends State<AnimatedRouteConnector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    if (widget.isRiding && !widget.exitQrActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedRouteConnector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRiding && !widget.exitQrActive) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Static connector for Available / Locked
    if (!widget.isRiding) {
      return Container(
        width: 56,
        margin: const EdgeInsets.only(top: 28),
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Static grey dashed line
            const DashedPerforationLine(
              color: Color(0xFF707975),
              dashWidth: 4,
              dashSpace: 3,
              strokeWidth: 2,
            ),
            // Center white badge with grey arrow
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Icon(
                Icons.arrow_forward,
                size: 18,
                color: Color(0xFF555555),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Stopped connector for Exit Gate (exitQrActive == true)
    if (widget.exitQrActive) {
      return Container(
        width: 56,
        margin: const EdgeInsets.only(top: 28),
        height: 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Solid / green dashed line across
            const DashedPerforationLine(
              color: Color(0xFF006B56),
              dashWidth: 4,
              dashSpace: 3,
              strokeWidth: 2,
            ),
            // Arrow stopped at the right end pointing to destination
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 18,
                  color: Color(0xFF006B56),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Animated journey connector during Riding (exitQrActive == false)
    return Container(
      width: 56,
      margin: const EdgeInsets.only(top: 28),
      height: 40,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;

          // Opacity fades in over 0-10% and fades out over 90-100%
          double opacity = 1.0;
          if (progress < 0.1) {
            opacity = progress / 0.1;
          } else if (progress > 0.9) {
            opacity = (1.0 - progress) / 0.1;
          }
          opacity = opacity.clamp(0.0, 1.0);

          return LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final fillWidth = totalWidth * progress;
              const arrowWidth = 22.0;
              final arrowLeft = (progress * (totalWidth - arrowWidth)).clamp(0.0, totalWidth - arrowWidth);

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Base grey dashed line underneath
                  const Positioned(
                    left: 0,
                    right: 0,
                    child: DashedPerforationLine(
                      color: Color(0xFFBEC9C3),
                      dashWidth: 4,
                      dashSpace: 3,
                      strokeWidth: 2,
                    ),
                  ),

                  // Animated green dashed line fill
                  if (opacity > 0)
                    Positioned(
                      left: 0,
                      width: fillWidth,
                      child: Opacity(
                        opacity: opacity,
                        child: const DashedPerforationLine(
                          color: Color(0xFF006B56),
                          dashWidth: 4,
                          dashSpace: 3,
                          strokeWidth: 2,
                        ),
                      ),
                    ),

                  // Animated moving green arrow
                  if (opacity > 0)
                    Positioned(
                      left: arrowLeft,
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: const Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: Color(0xFF006B56),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
