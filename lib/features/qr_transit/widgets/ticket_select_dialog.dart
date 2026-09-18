import 'package:flutter/material.dart';
import '../../../shared/models/ticket_model.dart';

/// 1:1 Strict Recreation of `#ticket-select-overlay` from Web Prototype/index.html
class TicketSelectDialog extends StatelessWidget {
  final List<TicketModel> tickets;
  final void Function(TicketModel ticket) onSelectTicket;
  final VoidCallback onCancel;

  const TicketSelectDialog({
    super.key,
    required this.tickets,
    required this.onSelectTicket,
    required this.onCancel,
  });

  static Future<TicketModel?> show(BuildContext context, {required List<TicketModel> tickets}) {
    return showDialog<TicketModel>(
      context: context,
      barrierColor: const Color(0x99000000),
      barrierDismissible: true,
      builder: (context) => TicketSelectDialog(
        tickets: tickets,
        onSelectTicket: (ticket) => Navigator.of(context).pop(ticket),
        onCancel: () => Navigator.of(context).pop(null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0x73BEC9C3),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Title
              const Text(
                'Select Ticket',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF005140), // var(--color-primary)
                ),
              ),
              const SizedBox(height: 8),

              // 2. Subtitle
              const Text(
                'You have multiple available tickets. Please select one to activate for scanning.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3E4945),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Ticket List (.ticket-select-list)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final t = tickets[index];
                    final peopleText = t.passengerCount == 1 ? '1 Person' : '${t.passengerCount} People';

                    return InkWell(
                      onTap: () => onSelectTicket(t),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F4F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0x4DBEC9C3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    t.origin,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF181C1A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                    color: Color(0xFF005140),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    t.destination,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF181C1A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  peopleText,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6E7A75),
                                  ),
                                ),
                                Text(
                                  '${t.totalFare} BDT',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF005140),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 4. Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFBA1A1A),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
