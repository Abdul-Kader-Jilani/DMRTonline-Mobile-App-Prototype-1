import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../shared/app_gradients.dart';
import '../../shared/models/ticket_model.dart';
import '../profile/widgets/loading_scene_overlay.dart';

/// 1:1 Strict Recreation of `#view-qr` from Web Prototype/index.html
class QrDisplayScreen extends StatefulWidget {
  final TicketModel ticket;
  final VoidCallback onBack;
  final VoidCallback onCompleteTrip;
  final VoidCallback? onPassEntryBarrier;
  final VoidCallback? onRegenerateQr;

  const QrDisplayScreen({
    super.key,
    required this.ticket,
    required this.onBack,
    required this.onCompleteTrip,
    this.onPassEntryBarrier,
    this.onRegenerateQr,
  });

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  Timer? _countdownTimer;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _initTimer();
  }

  void _initTimer() {
    _countdownTimer?.cancel();
    final expiryTime = widget.ticket.exitQrActive
        ? widget.ticket.exitQrExpiryTime
        : widget.ticket.qrExpiryTime;

    if (expiryTime != null) {
      final diff = expiryTime.difference(DateTime.now()).inSeconds;
      _secondsLeft = diff > 0 ? diff : 0;
    } else {
      _secondsLeft = widget.ticket.qrDurationSeconds;
    }

    if (_secondsLeft > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_secondsLeft > 0) {
            _secondsLeft--;
          } else {
            _secondsLeft = 0;
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool get _isExpired => _secondsLeft <= 0;
  bool get _isExitMode =>
      widget.ticket.status == TicketStatus.riding || widget.ticket.exitQrActive;

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    final personText = widget.ticket.passengerCount == 1
        ? '1 Passenger'
        : '${widget.ticket.passengerCount} Passengers';

    final badgeText = _isExitMode
        ? 'Exit Pass • $personText'
        : 'Single Journey • $personText';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppGradients.pageGradient,
        ),
        child: Column(
          children: [
            // 1. QR App Bar (.qr-app-bar)
            Container(
              padding: EdgeInsets.fromLTRB(8, topSafe + 4, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: widget.onBack,
                  ),
                  Expanded(
                    child: Text(
                      _isExitMode ? 'Show at Exit Reader' : 'Show at Reader',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance back button
                ],
              ),
            ),

            // 2. QR Content (.qr-content)
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomSafe),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  // 2.1 Route Information Card (.route-info-card)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14003328),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                widget.ticket.origin,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF005140),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.east,
                                size: 18,
                                color: Color(0xFF005140),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                widget.ticket.destination,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF005140),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0x1A006B56),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF006B56),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2.2 Passenger QR Code Card (.qr-code-area)
                  Center(
                    child: AnimatedOpacity(
                      opacity: _isExpired ? 0.3 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        width: 270,
                        height: 270,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF006B56),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x2600503A),
                              blurRadius: 30,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 4 Green Viewfinder Corners
                            const Positioned(
                              top: 0,
                              left: 0,
                              child: _ScanCorner(isTop: true, isLeft: true),
                            ),
                            const Positioned(
                              top: 0,
                              right: 0,
                              child: _ScanCorner(isTop: true, isLeft: false),
                            ),
                            const Positioned(
                              bottom: 0,
                              left: 0,
                              child: _ScanCorner(isTop: false, isLeft: true),
                            ),
                            const Positioned(
                              bottom: 0,
                              right: 0,
                              child: _ScanCorner(isTop: false, isLeft: false),
                            ),

                            // Crisp QR Code
                            QrImageView(
                              data: 'DMRT-${widget.ticket.id}-${widget.ticket.origin}-${widget.ticket.destination}-${widget.ticket.purchaseTime.millisecondsSinceEpoch}',
                              version: QrVersions.auto,
                              size: 200,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF005140),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF181C1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2.3 Timer Pill & Actions (.timer-section)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isExpired
                            ? const Color(0xFFBA1A1A)
                            : const Color(0xFFE6E9E5), // var(--color-surface-high)
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: _isExpired
                              ? const Color(0xFFBA1A1A)
                              : const Color(0xFFE0E3E0), // var(--color-surface-highest)
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            size: 18,
                            color: _isExpired
                                ? Colors.white
                                : const Color(0xFF005140), // var(--color-primary)
                          ),
                          const SizedBox(width: 8),
                          if (_isExpired)
                            const Text(
                              'QR expired',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            )
                          else ...[
                            const Text(
                              'Expires in ',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF3E4945), // var(--color-on-surface-variant)
                              ),
                            ),
                            Text(
                              '${_secondsLeft}s',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _secondsLeft <= 10
                                    ? const Color(0xFFBA1A1A) // var(--color-error)
                                    : const Color(0xFF005140), // var(--color-primary)
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons (.qr-actions)
                  _buildActionButtons(),
                  const SizedBox(height: 16),

                  // 2.4 Commuter Warning Bar (.warning-bar)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x0D005140),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0x26005140),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFF005140),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isExitMode
                                ? 'Please show this Exit QR code at the gate reader. Click "Tap to Pass Exit Barrier" to open the barrier and complete your trip.'
                                : 'Please show this QR code at the gate reader. Click "Tap to Pass Entry Barrier" to open the barrier and start your trip.',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3E4945),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isExitMode) {
      if (!_isExpired) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => LoadingSceneOverlay.runWithLoading(
              context,
              'Passing through exit barrier...',
              () => widget.onCompleteTrip(),
            ),
            icon: const Icon(Icons.sensor_door, size: 20, color: Colors.white),
            label: const Text(
              'Tap to Pass Exit Barrier',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005140),
              elevation: 4,
              shadowColor: const Color(0x33005140),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        );
      } else {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => LoadingSceneOverlay.runWithLoading(
              context,
              'Regenerating QR code...',
              () {
                _initTimer();
                widget.onRegenerateQr?.call();
              },
            ),
            icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
            label: const Text(
              'Regenerate Exit QR',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005140),
              elevation: 4,
              shadowColor: const Color(0x33005140),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        );
      }
    } else {
      // Entry Mode
      if (!_isExpired) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => LoadingSceneOverlay.runWithLoading(
              context,
              'Passing through entry barrier...',
              () => widget.onPassEntryBarrier?.call(),
            ),
            icon: const Icon(Icons.sensor_door, size: 20, color: Colors.white),
            label: const Text(
              'Tap to Pass Entry Barrier',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005140),
              elevation: 4,
              shadowColor: const Color(0x33005140),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        );
      } else {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => LoadingSceneOverlay.runWithLoading(
              context,
              'Regenerating QR code...',
              () {
                _initTimer();
                widget.onRegenerateQr?.call();
              },
            ),
            icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
            label: const Text(
              'Regenerate QR Code',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005140),
              elevation: 4,
              shadowColor: const Color(0x33005140),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        );
      }
    }
  }
}

class _ScanCorner extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _ScanCorner({
    required this.isTop,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xFF005140), width: 3.5)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xFF005140), width: 3.5)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xFF005140), width: 3.5)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xFF005140), width: 3.5)
              : BorderSide.none,
        ),
      ),
    );
  }
}
