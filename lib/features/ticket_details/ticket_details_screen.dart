import 'package:flutter/material.dart';
import '../../shared/app_gradients.dart';
import '../../shared/dynamic_ticket_notch.dart';
import '../../shared/models/ticket_model.dart';
import '../home/widgets/animated_route_connector.dart';
import '../home/widgets/dashed_perforation_line.dart';
import '../home/widgets/ticket_wave_clipper.dart';
import '../profile/widgets/loading_scene_overlay.dart';
import 'widgets/refund_confirm_dialog.dart';

/// 1:1 Strict Recreation of `#view-details` from Web Prototype/index.html
class TicketDetailsScreen extends StatelessWidget {
  final TicketModel ticket;
  final bool isLocked;
  final VoidCallback onBack;
  final VoidCallback? onUseTicket;
  final VoidCallback? onShowQr;
  final void Function(TicketModel ticket)? onRefundTicket;

  const TicketDetailsScreen({
    super.key,
    required this.ticket,
    this.isLocked = false,
    required this.onBack,
    this.onUseTicket,
    this.onShowQr,
    this.onRefundTicket,
  });

  bool get _isTicketLocked => isLocked || ticket.status == TicketStatus.locked;

  void _handleRefund(BuildContext context) async {
    final confirmed = await RefundConfirmDialog.show(
      context,
      ticketPrice: ticket.totalFare,
    );
    if (confirmed == true && onRefundTicket != null) {
      onRefundTicket!(ticket);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

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
            // 1. Detail App Bar (.detail-app-bar)
            Container(
              padding: EdgeInsets.fromLTRB(8, topSafe + 2, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: onBack,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Ticket Details',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Detail Content (.detail-content)
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(14, 2, 14, 16 + bottomSafe),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0x4DBEC9C3),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A000000),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 2.1 Wave Header with Status Badge
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(27)),
                          child: _buildWaveHeader(context),
                        ),

                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0x1ABEC9C3),
                        ),

                        // 2.2 Route Info Section
                        _buildRouteSection(),

                        // Notch Row 1
                        _buildNotchRow(),

                        // 2.3 Fare & Passenger Count Info
                        _buildFareAndPassengerRow(),

                        // Notch Row 2
                        _buildNotchRow(),

                        // 2.4 Purchase Date & Time
                        _buildPurchaseDateTimeRow(),

                        // Notch Row 3
                        _buildNotchRow(),

                        // 2.5 Expiry Alert Row
                        _buildExpiryAlertRow(),

                        // Notch Row 4 (Only for Available / Locked)
                        if (_isTicketLocked || ticket.status == TicketStatus.available) ...[
                          _buildNotchRow(),

                          // 2.6 Refund Policy Section
                          _buildRefundSection(context),
                        ],

                        // Notch Row 5
                        _buildNotchRow(),

                        // 2.7 Action Section ("Use Ticket" / "Current Trip" / "Locked")
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(27)),
                          child: _buildActionSection(context),
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

  Widget _buildWaveHeader(BuildContext context) {
    return SizedBox(
      height: 70,
      child: Stack(
        children: [
          // S-Curve Wave Mask Gradient
          Positioned.fill(
            child: ClipPath(
              clipper: TicketWaveClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: _isTicketLocked
                      ? const LinearGradient(
                          colors: [Color(0xFF707975), Color(0xFFA2ACB0)],
                        )
                      : ticket.status == TicketStatus.riding
                          ? const LinearGradient(
                              colors: [Color(0xFFBA1A1A), Color(0xFFE53935)],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFF005140), Color(0xFF0B9175)],
                            ),
                ),
              ),
            ),
          ),

          // Left: Status Badge + SINGLE JOURNEY
          Positioned(
            left: 16,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status Badge
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
                      _buildStatusIcon(),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusLabel(),
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

          // Right Top: Meta Row
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
                  ticket.formattedShortDate,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Container(width: 1, height: 11, color: const Color(0x66FFFFFF)),
                const SizedBox(width: 6),
                const Icon(
                  Icons.person,
                  size: 12,
                  color: Color(0xF2FFFFFF),
                ),
                const SizedBox(width: 3.5),
                Text(
                  ticket.passengerCount.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Container(width: 1, height: 11, color: const Color(0x66FFFFFF)),
                const SizedBox(width: 6),
                const Icon(
                  Icons.payments,
                  size: 12,
                  color: Color(0xF2FFFFFF),
                ),
                const SizedBox(width: 3.5),
                Text(
                  '৳${ticket.totalFare}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Right Bottom: Sub-header Row (Expiry + Refund / Time limit)
          Positioned(
            right: 12,
            bottom: 6,
            child: ticket.status == TicketStatus.riding
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
                        color: Color(0xFFB51B00),
                      ),
                      const SizedBox(width: 3.5),
                      Text(
                        'Exp: ${ticket.formattedShortExpiry}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3E4945),
                        ),
                      ),
                      if (_isTicketLocked || ticket.status == TicketStatus.available) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _handleRefund(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0x1ABA1A1A),
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
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (_isTicketLocked) {
      return const Icon(
        Icons.lock,
        size: 14,
        color: Color(0xFF707975),
      );
    }
    switch (ticket.status) {
      case TicketStatus.available:
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF006B56),
            shape: BoxShape.circle,
          ),
        );
      case TicketStatus.riding:
        return Icon(
          ticket.exitQrActive ? Icons.qr_code : Icons.train,
          size: 14,
          color: const Color(0xFFBA1A1A),
        );
      case TicketStatus.locked:
        return const Icon(
          Icons.lock,
          size: 14,
          color: Color(0xFF707975),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _getStatusLabel() {
    if (_isTicketLocked) return 'Locked';
    switch (ticket.status) {
      case TicketStatus.available:
        return 'Available';
      case TicketStatus.riding:
        return ticket.exitQrActive ? 'Exit Gate' : 'Riding';
      case TicketStatus.locked:
        return 'Locked';
      case TicketStatus.completed:
        return 'Completed';
      case TicketStatus.expired:
        return 'Expired';
      case TicketStatus.refunded:
        return 'Refunded';
    }
  }

  Color _getStatusTextColor() {
    if (_isTicketLocked) return const Color(0xFF707975);
    switch (ticket.status) {
      case TicketStatus.available:
        return const Color(0xFF006B56);
      case TicketStatus.riding:
        return const Color(0xFFBA1A1A);
      case TicketStatus.locked:
        return const Color(0xFF707975);
      default:
        return const Color(0xFF181C1A);
    }
  }

  Widget _buildRouteSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6E7A75), // var(--color-on-surface-variant)
                  ),
                ),
                const SizedBox(height: 6),
                _buildStationIcon(isOrigin: true),
                const SizedBox(height: 6),
                Text(
                  ticket.origin,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
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
            isRiding: ticket.status == TicketStatus.riding,
            exitQrActive: ticket.exitQrActive,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6E7A75), // var(--color-on-surface-variant)
                  ),
                ),
                const SizedBox(height: 6),
                _buildStationIcon(isOrigin: false),
                const SizedBox(height: 6),
                Text(
                  ticket.destination,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
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
    Color bgColor = const Color(0xFFF1F4F0);
    Color borderColor = const Color(0xFFBEC9C3);
    Color iconColor = const Color(0xFF6E7A75);

    if (ticket.status == TicketStatus.riding) {
      if (isOrigin) {
        bgColor = const Color(0xFF005140);
        borderColor = const Color(0xFF005140);
        iconColor = Colors.white;
      } else if (ticket.exitQrActive) {
        bgColor = const Color(0xFFD32F2F);
        borderColor = const Color(0xFFD32F2F);
        iconColor = Colors.white;
      }
    }

    return Container(
      width: 34,
      height: 34,
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
          size: 18,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildNotchRow() {
    return const SizedBox(
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Dashed Perforation Line
          Positioned(
            left: 12,
            right: 12,
            child: DashedPerforationLine(
              color: Color(0xFFBEC9C3),
              dashWidth: 5,
              dashSpace: 4,
              strokeWidth: 1.5,
            ),
          ),

          // Left Notch Cutout (Dynamic background gradient matching)
          Positioned(
            left: -12,
            child: SizedBox(
              width: 24,
              height: 24,
              child: DynamicTicketNotchCutout(
                isLeft: true,
              ),
            ),
          ),

          // Right Notch Cutout (Dynamic background gradient matching)
          Positioned(
            right: -12,
            child: SizedBox(
              width: 24,
              height: 24,
              child: DynamicTicketNotchCutout(
                isLeft: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareAndPassengerRow() {
    final personLabel = ticket.passengerCount == 1 ? '1 Person' : '${ticket.passengerCount} Persons';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Fare',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E7A75),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '৳ ${ticket.totalFare}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF005140),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Passengers',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E7A75),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                personLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF181C1A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseDateTimeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Purchase Date & Time',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E7A75),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            ticket.formattedFullPurchaseTime,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF181C1A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryAlertRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.schedule_outlined,
            size: 18,
            color: Color(0xFFBA1A1A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF181C1A),
                    ),
                    children: [
                      const TextSpan(
                        text: 'Expiry Time:  ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFBA1A1A),
                        ),
                      ),
                      TextSpan(
                        text: ticket.formattedFullExpiryTime,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF181C1A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'This ticket expires 24 hours after purchase.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6E7A75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Refund policy box (.refund-warning)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x0DBA1A1A), // rgba(186, 26, 26, 0.05)
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0x1ABA1A1A), // rgba(186, 26, 26, 0.10)
                width: 1,
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_rounded,
                  size: 18,
                  color: Color(0xFFBA1A1A),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Refund Policy',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFBA1A1A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'A 10% refund fee will be deducted. Refund must be done before the ticket expires.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                          color: Color(0xE6BA1A1A), // rgba(186, 26, 26, 0.9)
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Refund Ticket Button (.btn-refund)
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: () => _handleRefund(context),
              icon: const Icon(
                Icons.sync,
                size: 18,
                color: Colors.white,
              ),
              label: const Text(
                'Refund Ticket',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: const Color(0x4DBA1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context) {
    if (_isTicketLocked) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.lock, size: 16),
            label: const Text('Locked (Another Trip in Progress)'),
            style: ElevatedButton.styleFrom(
              disabledBackgroundColor: const Color(0xFFEBEFEB),
              disabledForegroundColor: const Color(0xFF6E7A75),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ),
      );
    }

    if (ticket.status == TicketStatus.riding) {
      final btnText = ticket.exitQrActive ? 'Show Exit QR' : 'Show Passenger QR';
      final icon = ticket.exitQrActive ? Icons.qr_code : Icons.train;

      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onShowQr,
            icon: Icon(icon, size: 16, color: Colors.white),
            label: Text(
              btnText,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005140),
              elevation: 3,
              shadowColor: const Color(0x33005140),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
        ),
      );
    }

    // Available -> "Use Ticket"
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton.icon(
          onPressed: onUseTicket != null
              ? () => LoadingSceneOverlay.runWithLoading(
                    context,
                    'Generating Ticket QR...',
                    () => onUseTicket!(),
                  )
              : null,
          icon: const Icon(Icons.qr_code_2, size: 16, color: Colors.white),
          label: const Text(
            'Use Ticket',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF005140),
            elevation: 3,
            shadowColor: const Color(0x33005140),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9999),
            ),
          ),
        ),
      ),
    );
  }
}
