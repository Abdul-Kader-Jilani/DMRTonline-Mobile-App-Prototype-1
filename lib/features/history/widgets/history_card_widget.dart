import 'package:flutter/material.dart';
import '../models/history_ticket_model.dart';

/// 1:1 Strict Pure Recreation of `.history-card` from Web Prototype/index.html
class HistoryCardWidget extends StatelessWidget {
  final HistoryTicketModel ticket;
  final VoidCallback? onTap;

  const HistoryCardWidget({
    super.key,
    required this.ticket,
    this.onTap,
  });

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final year = dt.year;
    final hour24 = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);

    return '$month $day, $year, $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white, // var(--color-surface-lowest)
        borderRadius: BorderRadius.circular(16), // var(--radius-lg)
        border: Border.all(
          color: const Color(0xFFE0E3E0), // var(--color-surface-highest)
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // var(--shadow-sm)
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header (.history-card__header)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date (.history-card__date)
                Expanded(
                  child: Text(
                    _formatDateTime(ticket.purchaseTime),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Color(0xFF3E4945), // var(--color-on-surface-variant)
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),

                // Status Badge (.history-card__badge)
                _buildBadge(),
              ],
            ),

            const SizedBox(height: 12),

            // 2. Body (.history-card__body)
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Route Timeline (.route-timeline)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.radio_button_checked,
                      size: 20,
                      color: Color(0xFF006B56), // var(--color-origin)
                    ),
                    Container(
                      width: 2,
                      height: 28,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFF555555), // .route-timeline__line
                    ),
                    const Icon(
                      Icons.location_on,
                      size: 20,
                      color: Color(0xFFD13014), // var(--color-destination)
                    ),
                  ],
                ),

                const SizedBox(width: 12),

                // Route Details (.route-details)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Origin From Group
                      const Text(
                        'From',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: Color(0xFF006B56), // var(--color-origin)
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ticket.origin,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF181C1A), // var(--color-on-surface)
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 10),

                      // Destination To Group
                      const Text(
                        'To',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: Color(0xFFD13014), // var(--color-destination)
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ticket.destination,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF181C1A), // var(--color-on-surface)
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Fare Info (.fare-info)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Passenger Count Badge (.fare-info__passenger-badge)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F4F0), // var(--color-surface-low)
                        border: Border.all(
                          color: const Color(0xFFE6E9E5), // var(--color-surface-high)
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '${ticket.passengerCount} Person${ticket.passengerCount > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: Color(0xFF3E4945), // var(--color-on-surface-variant)
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Fare Label & Amount (.fare-info__amount-group)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Fare',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFF3E4945), // var(--color-on-surface-variant)
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '৳ ${ticket.totalFare}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF005140), // var(--color-primary)
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge() {
    switch (ticket.status) {
      case HistoryStatus.completed:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0x1F006B56), // var(--color-completed-bg)
            borderRadius: BorderRadius.circular(9999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                size: 14,
                color: Color(0xFF006B56),
              ),
              SizedBox(width: 4),
              Text(
                'Completed',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF006B56), // var(--color-completed-text)
                ),
              ),
            ],
          ),
        );

      case HistoryStatus.expired:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE6E9E5), // var(--color-surface-high)
            borderRadius: BorderRadius.circular(9999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 14,
                color: Color(0xFF3E4945),
              ),
              SizedBox(width: 4),
              Text(
                'Expired',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF3E4945), // var(--color-on-surface-variant)
                ),
              ),
            ],
          ),
        );

      case HistoryStatus.refunded:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0x1ABA1A1A),
            borderRadius: BorderRadius.circular(9999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.currency_exchange,
                size: 14,
                color: Color(0xFFBA1A1A),
              ),
              SizedBox(width: 4),
              Text(
                'Refunded',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFFBA1A1A),
                ),
              ),
            ],
          ),
        );
    }
  }
}
