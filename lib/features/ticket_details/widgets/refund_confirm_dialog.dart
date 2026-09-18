import 'dart:ui';
import 'package:flutter/material.dart';

/// 1:1 Strict Recreation of #refund-confirm-overlay from Web Prototype/index.html
class RefundConfirmDialog extends StatelessWidget {
  final int ticketPrice;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const RefundConfirmDialog({
    super.key,
    required this.ticketPrice,
    required this.onConfirm,
    required this.onCancel,
  });

  static Future<bool?> show(BuildContext context, {required int ticketPrice}) {
    return showDialog<bool>(
      context: context,
      barrierColor: const Color(0x99000000), // rgba(0, 0, 0, 0.6)
      barrierDismissible: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: RefundConfirmDialog(
          ticketPrice: ticketPrice,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final refundFee = (ticketPrice * 0.1).round();
    final returnAmount = ticketPrice - refundFee;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // var(--radius-2xl)
            border: Border.all(
              color: const Color(0x73BEC9C3), // var(--color-outline-variant)
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header with Warning Icon (.confirm-title)
              const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFBA1A1A), // var(--color-error)
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Confirm Ticket Refund',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFBA1A1A), // var(--color-error)
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Body description (.confirm-text)
              const Text(
                'Are you sure you want to refund this ticket? This action cannot be undone.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF181C1A), // var(--color-on-surface)
                ),
              ),
              const SizedBox(height: 16),

              // 3. Calculation Details Box (.confirm-details)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F0), // var(--color-surface-low)
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0x73BEC9C3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Row 1: Ticket Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Ticket Price',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3E4945), // var(--color-on-surface-variant)
                            ),
                          ),
                        ),
                        Text(
                          '৳$ticketPrice',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF181C1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 2: Refund Fee (10%)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Refund Fee (10%)',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3E4945),
                            ),
                          ),
                        ),
                        Text(
                          '৳$refundFee',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB51B00), // var(--color-secondary)
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Dashed Divider
                    CustomPaint(
                      painter: _DashedLinePainter(
                        color: const Color(0xFFBEC9C3),
                      ),
                      size: const Size(double.infinity, 1),
                    ),
                    const SizedBox(height: 10),

                    // Row 3: You Will Get Back
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'You Will Get Back',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF005140), // var(--color-primary)
                            ),
                          ),
                        ),
                        Text(
                          '৳$returnAmount',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF005140), // var(--color-primary)
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Action Buttons (.confirm-actions)
              Row(
                children: [
                  // Cancel Button (.btn-confirm-no)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onCancel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEBEFEB), // var(--color-surface-low)
                          foregroundColor: const Color(0xFF181C1A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Yes, Refund Button (.btn-confirm-yes)
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: onConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBA1A1A), // var(--color-error)
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        child: const Text(
                          'Yes, Refund',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
