import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../shared/app_gradients.dart';
import '../../shared/dynamic_ticket_notch.dart';
import '../../shared/models/ticket_model.dart';
import '../home/widgets/dashed_perforation_line.dart';
import '../home/widgets/ticket_wave_clipper.dart';
import 'widgets/hold_to_confirm_button.dart';
import 'widgets/payment_method_sheet.dart';

/// 1:1 Strict Recreation of `#view-payment` from Web Prototype/index.html
class PaymentScreen extends StatefulWidget {
  final String origin;
  final String destination;
  final int passengerCount;
  final int totalFare;
  final String? initialMethodKey;
  final String? initialMethodName;
  final VoidCallback onBack;
  final void Function(TicketModel purchasedTicket) onTicketPurchased;

  const PaymentScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.passengerCount,
    required this.totalFare,
    this.initialMethodKey,
    this.initialMethodName,
    required this.onBack,
    required this.onTicketPurchased,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late String _selectedMethodKey;
  late String _selectedMethodName;

  @override
  void initState() {
    super.initState();
    _selectedMethodKey = widget.initialMethodKey ?? 'mfs';
    _selectedMethodName = widget.initialMethodName ?? 'Mobile Finance (bKash/Nagad)';
  }

  void _openMethodPicker() async {
    final chosen = await PaymentMethodSheet.show(
      context,
      selectedKey: _selectedMethodKey,
    );

    if (chosen != null) {
      setState(() {
        _selectedMethodKey = chosen.key;
        _selectedMethodName = chosen.key == 'mfs'
            ? 'Mobile Finance (bKash/Nagad)'
            : (chosen.key == 'card' ? 'Debit / Credit Card' : 'Internet Banking');
      });
    }
  }

  void _handleConfirmed() {
    final now = DateTime.now();
    final randomId = 'TKT-${(1000 + (now.millisecondsSinceEpoch % 9000))}';
    final farePerPerson = widget.passengerCount > 0
        ? (widget.totalFare / widget.passengerCount).round()
        : widget.totalFare;

    final newTicket = TicketModel(
      id: randomId,
      origin: widget.origin,
      destination: widget.destination,
      passengerCount: widget.passengerCount,
      farePerPerson: farePerPerson,
      totalFare: widget.totalFare,
      status: TicketStatus.available,
      purchaseTime: now,
      paymentMethod: _selectedMethodName,
    );

    widget.onTicketPurchased(newTicket);
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final todayShort = DateFormat('d MMM').format(DateTime.now());

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
                    onPressed: widget.onBack,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Payment',
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
                        // 2.1 Wave Header with "Review" badge
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(27)),
                          child: _buildWaveHeader(todayShort),
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

                        // 2.4 Payment Method Row (Tap to open sheet)
                        _buildPaymentMethodRow(),

                        // Notch Row 3
                        _buildNotchRow(),

                        // 2.5 Validity & Expiry
                        _buildValidityExpiryRow(),

                        // Notch Row 4
                        _buildNotchRow(),

                        // 2.6 Hold to Purchase Interactive Button
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(27)),
                          child: HoldToConfirmButton(
                            onConfirmed: _handleConfirmed,
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

  Widget _buildWaveHeader(String todayShort) {
    return SizedBox(
      height: 70,
      child: Stack(
        children: [
          // Green Wave Mask
          Positioned.fill(
            child: ClipPath(
              clipper: TicketWaveClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF006B56),
                ),
              ),
            ),
          ),

          // Left: Review Badge + SINGLE JOURNEY
          Positioned(
            left: 16,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF006B56),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Review',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: Color(0xFF006B56),
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
                  todayShort,
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
                  widget.passengerCount.toString().padLeft(2, '0'),
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
                  '৳${widget.totalFare}',
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

          // Right Bottom: Time limit
          const Positioned(
            right: 12,
            bottom: 6,
            child: Row(
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
            ),
          ),
        ],
      ),
    );
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
                  widget.origin,
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

          // Route Connector Center (.route-connector)
          Container(
            width: 48,
            margin: const EdgeInsets.only(top: 22),
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dashed Line Across Center
                const DashedPerforationLine(
                  color: Color(0xFF707975),
                  dashWidth: 4,
                  dashSpace: 3,
                  strokeWidth: 2,
                ),

                // Center White Badge with Arrow
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Color(0xFF555555),
                  ),
                ),
              ],
            ),
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
                  widget.destination,
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

    if (isOrigin) {
      bgColor = const Color(0xFF005140);
      borderColor = const Color(0xFF005140);
      iconColor = Colors.white;
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
          isOrigin ? Icons.train : Icons.place,
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
    final personLabel = widget.passengerCount == 1 ? '1 Person' : '${widget.passengerCount} Persons';
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
                  letterSpacing: 0.5,
                  color: Color(0xFF6E7A75),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '৳ ${widget.totalFare}',
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
                  letterSpacing: 0.5,
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

  Widget _buildPaymentMethodRow() {
    return InkWell(
      onTap: _openMethodPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6E7A75),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedMethodName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF181C1A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF6E7A75),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidityExpiryRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.schedule,
            size: 18,
            color: Color(0xFFBA1A1A),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Validity & Expiry',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBA1A1A),
                    letterSpacing: 0.1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'This ticket expires 24 hours after purchase.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
}
