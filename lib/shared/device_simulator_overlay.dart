import 'package:flutter/material.dart';
import 'app_gradients.dart';

/// Pure Flutter responsive simulator wrapper.
/// On desktop/browser (screens wider than 500px), wraps the app inside an
/// authentic mobile phone bezel with instant 1-tap width switcher buttons:
/// [360px], [380px], [400px], [420px], and [Full].
class DeviceSimulatorOverlay extends StatefulWidget {
  final Widget child;

  const DeviceSimulatorOverlay({super.key, required this.child});

  @override
  State<DeviceSimulatorOverlay> createState() => _DeviceSimulatorOverlayState();
}

class _DeviceSimulatorOverlayState extends State<DeviceSimulatorOverlay> {
  // Default to 380px width, general height 840px
  double _selectedWidth = 380.0;
  bool _isFullScreen = false;
  static const double _generalHeight = 840.0;
  static const double _safeTop = 44.0;
  static const double _safeBottom = 24.0;

  final List<double> _presetWidths = [360.0, 380.0, 400.0, 420.0];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If running on a real mobile screen or user selected Full Viewport
        if (constraints.maxWidth <= 500 || _isFullScreen) {
          return Stack(
            children: [
              Positioned.fill(child: widget.child),
              if (constraints.maxWidth > 500)
                Positioned(
                  top: 14,
                  right: 14,
                  child: _buildFloatingSwitcher(constraints),
                ),
            ],
          );
        }

        final targetWidth = _selectedWidth;
        const targetHeight = _generalHeight;

        // Calculate scale if browser window height is smaller than targetHeight
        final availableHeight = constraints.maxHeight - 80; // margin for top toolbar
        final scale = (availableHeight > 0 && availableHeight < targetHeight)
            ? availableHeight / targetHeight
            : 1.0;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A), // Dark slate developer backdrop
          body: Stack(
            alignment: Alignment.center,
            children: [
              // Centered Realistic Phone Bezel Frame
              Center(
                child: Transform.scale(
                  scale: scale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    width: targetWidth,
                    height: targetHeight,
                    decoration: BoxDecoration(
                      gradient: AppGradients.pageGradient, // Base app background
                      borderRadius: BorderRadius.circular(44),
                      border: Border.all(
                        color: const Color(0xFF1E293B), // Titanium phone bezel
                        width: 10,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 36,
                          spreadRadius: 4,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(34),
                      child: Stack(
                        children: [
                          // App Content with injected Safe Area Insets
                          Positioned.fill(
                            child: MediaQuery(
                              data: MediaQuery.of(context).copyWith(
                                padding: const EdgeInsets.only(
                                  top: _safeTop,
                                  bottom: _safeBottom,
                                ),
                                viewPadding: const EdgeInsets.only(
                                  top: _safeTop,
                                  bottom: _safeBottom,
                                ),
                              ),
                              child: widget.child,
                            ),
                          ),

                          // Dynamic Camera Notch Cutout
                          Positioned(
                            top: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                width: 110,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Floating Width Switcher Toolbar
              Positioned(
                top: 14,
                child: _buildFloatingSwitcher(constraints),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingSwitcher(BoxConstraints constraints) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xEE1E293B),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.devices, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          const Text(
            'Simulator:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 8),

          // 1-Tap Preset Buttons: 360, 380, 400, 420
          ..._presetWidths.map((w) {
            final isSelected = !_isFullScreen && (_selectedWidth - w).abs() < 1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isFullScreen = false;
                    _selectedWidth = w;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF005140) : const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    '${w.toInt()}px',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
            );
          }),

          // Full Screen Viewport Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () {
                setState(() {
                  _isFullScreen = !_isFullScreen;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isFullScreen ? const Color(0xFF005140) : const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isFullScreen ? const Color(0xFF10B981) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'Full',
                  style: TextStyle(
                    color: _isFullScreen ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: _isFullScreen ? FontWeight.w700 : FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),
          Container(width: 1, height: 16, color: Colors.white24),
          const SizedBox(width: 8),

          // Active Dimension Label
          Text(
            _isFullScreen
                ? 'Full (${constraints.maxWidth.toInt()}px)'
                : '${_selectedWidth.toInt()}×${_generalHeight.toInt()}',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
