import 'package:flutter/material.dart';

/// 1:1 Reconstruction of `.no-tickets-placeholder` from Web Prototype/index.html
class NoTicketsPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;

  const NoTicketsPlaceholder({
    super.key,
    this.title = 'No active tickets available.',
    this.subtitle = "Select 'Buy Ticket' below to purchase a journey ticket.",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF), // var(--color-surface-lowest)
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x4DBEC9C3), // rgba(190, 201, 195, 0.3)
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // 0 1px 3px rgba(0, 0, 0, 0.08)
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Opacity(
            opacity: 0.5,
            child: Icon(
              Icons.confirmation_number_outlined,
              size: 48,
              color: Color(0xFF6E7A75), // var(--color-outline)
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF181C1A), // var(--color-on-surface)
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF3E4945), // var(--color-on-surface-variant)
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
