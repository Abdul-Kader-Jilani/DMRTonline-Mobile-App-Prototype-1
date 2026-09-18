import 'package:flutter/material.dart';
import '../../../shared/dynamic_ticket_notch.dart';
import 'animated_route_connector.dart';
import 'dashed_perforation_line.dart';
import 'ticket_wave_clipper.dart';

/// Supported status for ticket card display
enum TicketCardStatus {
  available,
  riding,
  locked,
}

/// 1:1 Authentic DMRT Single Journey Ticket Card from Web Prototype/index.html
class TicketCardWidget extends StatelessWidget {
  final String origin;
  final String destination;
  final String date;
  final int passengerCount;
  final int fare;
  final String expiry;
  final TicketCardStatus status;
  final bool exitQrActive;
  final VoidCallback? onUseTicket;
  final VoidCallback? onRefund;
  final VoidCallback? onTap;

  const TicketCardWidget({
    super.key,
    this.origin = 'Uttara North',
    this.destination = 'Motijheel',
    this.date = '11 Sep',
    this.passengerCount = 1,
    this.fare = 60,
    this.expiry = '12 Sep',
    this.status = TicketCardStatus.available,
    this.exitQrActive = false,
    this.onUseTicket,
    this.onRefund,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF), // var(--color-surface-lowest)
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: const Color(0x4DBEC9C3), // rgba(190, 201, 195, 0.3)
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000), // var(--shadow-md)
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. TICKET HEADER with Signature S-Curve Wave Mask
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(31)),
              child: _buildHeader(),
            ),

            // 2. DIVIDER
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0x1ABEC9C3),
            ),

            // 3. ROUTE SECTION (Origin -> Connector -> Destination)
            _buildRouteSection(),

            // 4. NOTCH ROW with Circular Side Cutouts & Dashed Perforation
            _buildNotchRow(),

            // 5. ACTION BUTTON SECTION ("Use Ticket" / "Current Trip" / "Show Exit QR" / "Locked")
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(31)),
              child: _buildActionSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isRiding = status == TicketCardStatus.riding;

    return SizedBox(
      height: 74,
      child: Stack(
        children: [
          // SVG Wave Mask Indicator Gradient (.ticket-indicator)
          Positioned.fill(
            child: ClipPath(
              clipper: TicketWaveClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: _getHeaderGradient(),
                ),
              ),
            ),
          ),

          // Left Content: Status Pill Badge + "SINGLE JOURNEY"
          Positioned(
            left: 16,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status Badge (.status-badge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildStatusDotOrIcon(),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: _getStatusTextColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'SINGLE JOURNEY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Right Top: Meta Row (.ticket-header-meta: White text on wave)
          Positioned(
            right: 16,
            top: 13,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Color(0xF2FFFFFF),
                ),
                const SizedBox(width: 3.5),
                Text(
                  date,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 1,
                  height: 11,
                  color: const Color(0x66FFFFFF),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.person,
                  size: 12,
                  color: Color(0xF2FFFFFF),
                ),
                const SizedBox(width: 3.5),
                Text(
                  passengerCount.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 1,
                  height: 11,
                  color: const Color(0x66FFFFFF),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.payments,
                  size: 12,
                  color: Color(0xF2FFFFFF),
                ),
                const SizedBox(width: 3.5),
                Text(
                  '৳$fare',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),

          // Right Bottom: Sub-header Row (Time limit for riding / Expiry + Refund for available/locked)
          Positioned(
            right: 12,
            bottom: 5,
            child: isRiding
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: Color(0xFFBA1A1A),
                      ),
                      SizedBox(width: 3.5),
                      Text(
                        'Time limit: 60 Minutes',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3E4945),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 12,
                        color: Color(0xFFBA1A1A),
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        expiry.startsWith('Exp:') ? expiry : 'Exp: $expiry',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3E4945),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Refund Pill Button (.ticket-card-refund-btn)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onRefund,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0x1ABA1A1A), // rgba(186, 26, 26, 0.1)
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.currency_exchange,
                                size: 12,
                                color: Color(0xFFBA1A1A),
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Refund',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFBA1A1A),
                                ),
                              ),
                              SizedBox(width: 1),
                              Icon(
                                Icons.chevron_right,
                                size: 13,
                                color: Color(0xFFBA1A1A),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSection() {
    final isRiding = status == TicketCardStatus.riding;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Origin Station Column (Left)
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Origin',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6E7A75), // var(--color-on-surface-variant)
                  ),
                ),
                const SizedBox(height: 8),
                _buildStationIcon(isOrigin: true),
                const SizedBox(height: 8),
                Text(
                  origin,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181C1A),
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Route Connector Center (.route-connector with animation when riding)
          AnimatedRouteConnector(
            isRiding: isRiding,
            exitQrActive: exitQrActive,
          ),

          // Destination Station Column (Right)
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Destination',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6E7A75), // var(--color-on-surface-variant)
                  ),
                ),
                const SizedBox(height: 8),
                _buildStationIcon(isOrigin: false),
                const SizedBox(height: 8),
                Text(
                  destination,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181C1A),
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationIcon({required bool isOrigin}) {
    Color bgColor = const Color(0xFFF1F4F0); // var(--color-surface-low)
    Color borderColor = const Color(0xFFBEC9C3); // var(--color-outline-variant)
    Color iconColor = const Color(0xFF6E7A75);

    if (status == TicketCardStatus.riding) {
      if (isOrigin) {
        // Active Origin -> Solid Primary Green
        bgColor = const Color(0xFF005140);
        borderColor = const Color(0xFF005140);
        iconColor = Colors.white;
      } else if (exitQrActive) {
        // Active Destination when in Exit Gate mode -> Red
        bgColor = const Color(0xFFD32F2F);
        borderColor = const Color(0xFFD32F2F);
        iconColor = Colors.white;
      }
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bgColor,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          isOrigin ? Icons.train : Icons.location_on,
          size: 22,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildNotchRow() {
    return const SizedBox(
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Middle Dashed Perforation Line
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: DashedPerforationLine(
              color: Color(0xFFBEC9C3),
              dashWidth: 6,
              dashSpace: 4,
              strokeWidth: 1.5,
            ),
          ),

          // Left Circular Notch Cutout
          Positioned(
            left: -12,
            child: SizedBox(
              width: 24,
              height: 24,
              child: DynamicTicketNotchCutout(isLeft: true),
            ),
          ),

          // Right Circular Notch Cutout
          Positioned(
            right: -12,
            child: SizedBox(
              width: 24,
              height: 24,
              child: DynamicTicketNotchCutout(isLeft: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    if (status == TicketCardStatus.locked) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          children: [
            Container(
              height: 42,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFEBEFEB), // var(--color-surface-container)
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 16, color: Color(0xFF6E7A75)),
                  SizedBox(width: 8),
                  Text(
                    'Trip Locked',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6E7A75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Finish your active journey to unlock other trips.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Color(0xFF6E7A75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final isRiding = status == TicketCardStatus.riding;
    final btnText = isRiding
        ? (exitQrActive ? 'Show Exit QR' : 'Current Trip')
        : 'Use Ticket';
    final btnIcon = isRiding
        ? (exitQrActive ? Icons.qr_code : Icons.train)
        : Icons.qr_code_scanner;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onUseTicket,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: const LinearGradient(
                colors: [Color(0xFF0B9175), Color(0xFF005140)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0x73BEC9C3), // rgba(190, 201, 195, 0.45)
                width: 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33005140),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(btnIcon, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  btnText,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getHeaderGradient() {
    switch (status) {
      case TicketCardStatus.available:
        return const LinearGradient(
          colors: [Color(0xFF005140), Color(0xFF0B9175)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case TicketCardStatus.riding:
        return const LinearGradient(
          colors: [Color(0xFFBA1A1A), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case TicketCardStatus.locked:
        return const LinearGradient(
          colors: [Color(0xFF707975), Color(0xFFA2ACB0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Widget _buildStatusDotOrIcon() {
    switch (status) {
      case TicketCardStatus.available:
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF006B56),
            shape: BoxShape.circle,
          ),
        );
      case TicketCardStatus.riding:
        return Icon(
          exitQrActive ? Icons.qr_code : Icons.train,
          size: 16,
          color: const Color(0xFFBA1A1A),
        );
      case TicketCardStatus.locked:
        return const Icon(Icons.lock, size: 16, color: Color(0xFF6E7A75));
    }
  }

  String _getStatusText() {
    switch (status) {
      case TicketCardStatus.available:
        return 'Available';
      case TicketCardStatus.riding:
        return exitQrActive ? 'Exit Gate' : 'Riding';
      case TicketCardStatus.locked:
        return 'Locked';
    }
  }

  Color _getStatusTextColor() {
    switch (status) {
      case TicketCardStatus.available:
        return const Color(0xFF006B56);
      case TicketCardStatus.riding:
        return const Color(0xFFBA1A1A);
      case TicketCardStatus.locked:
        return const Color(0xFF6E7A75);
    }
  }
}



