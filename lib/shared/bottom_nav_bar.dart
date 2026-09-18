import 'dart:ui';
import 'package:flutter/material.dart';

/// 1:1 Pure recreation of `.bottom-nav-rounded` from Web Prototype/index.html
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onScanPressed;

  const BottomNavBar({
    super.key,
    this.currentIndex = 0,
    required this.onTabSelected,
    required this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navHeight = 64.0 + bottomPadding;
    final totalHeight = 28.0 + navHeight; // 28px floating FAB top clearance + navHeight

    return SizedBox(
      height: totalHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. Shadow Layer for the Concave Notched Path
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: navHeight,
            child: CustomPaint(
              painter: _BottomNavShadowPainter(),
            ),
          ),

          // 2. Frosted Glass Masked Navigation Bar (.bottom-nav-rounded__bg)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: navHeight,
            child: ClipPath(
              clipper: _BottomNavNotchClipper(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  width: double.infinity,
                  height: navHeight,
                  color: const Color(0xEDFFFFFF), // rgba(255, 255, 255, 0.93)
                ),
              ),
            ),
          ),

          // 3. Navigation Content (.bottom-nav-rounded__content)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding,
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tab 0: Home (.bottom-nav__item)
                _buildNavItem(
                  icon: Icons.account_balance_wallet_outlined,
                  activeIcon: Icons.account_balance_wallet,
                  label: 'Home',
                  index: 0,
                ),

                // Tab 1: Buy Ticket (.bottom-nav__item)
                _buildNavItem(
                  icon: Icons.confirmation_number_outlined,
                  activeIcon: Icons.confirmation_number,
                  label: 'Buy Ticket',
                  index: 1,
                ),

                // Center FAB Placeholder (.bottom-nav-rounded__fab-placeholder)
                const Expanded(
                  child: SizedBox(
                    height: double.infinity,
                  ),
                ),

                // Tab 2: History (.bottom-nav__item)
                _buildNavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  label: 'History',
                  index: 2,
                ),

                // Tab 3: Profile (.bottom-nav__item)
                _buildNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                  index: 3,
                ),
              ],
            ),
          ),

          // 4. Center Floating Glowing Scan FAB (.bottom-nav-rounded__fab)
          Positioned(
            top: 0,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  // Directional drop shadow
                  BoxShadow(
                    color: Color(0x66005140), // 0 4px 14px rgba(0, 81, 64, 0.4)
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                  // High-intensity emerald neon core
                  BoxShadow(
                    color: Color(0xD910B981), // 0 0 20px rgba(16, 185, 129, 0.85)
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: Offset.zero,
                  ),
                  // Atmospheric ambient neon glow bloom
                  BoxShadow(
                    color: Color(0x7310B981), // 0 0 40px rgba(16, 185, 129, 0.45)
                    blurRadius: 36,
                    spreadRadius: 2,
                    offset: Offset.zero,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onScanPressed,
                  customBorder: const CircleBorder(),
                  splashColor: Colors.white24,
                  highlightColor: Colors.white10,
                  child: Ink(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0B9175),
                          Color(0xFF005140),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    const primaryColor = Color(0xFF005140); // var(--color-primary)
    const variantColor = Color(0xFF6E7A75); // var(--color-on-surface-variant)

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTabSelected(index),
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with 40x28 Active Pill Highlight (.material-symbols-outlined::before)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: 40,
                height: 28,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0x1A005140) // rgba(0, 81, 64, 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color: isSelected ? primaryColor : variantColor,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Nav Label (.bottom-nav__label)
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  height: 14 / 11,
                  letterSpacing: 0.1,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primaryColor : variantColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Precise SVG concave dip path matching:
/// M 0 0 L 135 0 C 150 0 155 32 180 32 C 205 32 210 0 225 0 L 360 0 L 360 64 L 0 64 Z
class _BottomNavNotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final scaleX = w / 360.0;

    path.moveTo(0, 0);
    path.lineTo(135 * scaleX, 0);
    path.cubicTo(
      150 * scaleX,
      0,
      155 * scaleX,
      32,
      180 * scaleX,
      32,
    );
    path.cubicTo(
      205 * scaleX,
      32,
      210 * scaleX,
      0,
      225 * scaleX,
      0,
    );
    path.lineTo(w, 0);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Custom painter for top drop shadow matching:
/// filter: drop-shadow(0px -4px 10px rgba(0, 0, 0, 0.15))
class _BottomNavShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final scaleX = w / 360.0;

    path.moveTo(0, 0);
    path.lineTo(135 * scaleX, 0);
    path.cubicTo(
      150 * scaleX,
      0,
      155 * scaleX,
      32,
      180 * scaleX,
      32,
    );
    path.cubicTo(
      205 * scaleX,
      32,
      210 * scaleX,
      0,
      225 * scaleX,
      0,
    );
    path.lineTo(w, 0);
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    final shadowPaint = Paint()
      ..color = const Color(0x26000000) // rgba(0, 0, 0, 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.save();
    canvas.translate(0, -4);
    canvas.drawPath(path, shadowPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
