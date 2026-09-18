import 'package:flutter/material.dart';

class PaymentMethodOption {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color badgeBg;

  const PaymentMethodOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.badgeBg,
  });
}

/// 1:1 Strict Recreation of `#payment-method-overlay` from Web Prototype/index.html
class PaymentMethodSheet extends StatelessWidget {
  final String? selectedMethodKey;
  final void Function(PaymentMethodOption method) onSelectMethod;

  const PaymentMethodSheet({
    super.key,
    this.selectedMethodKey,
    required this.onSelectMethod,
  });

  static const List<PaymentMethodOption> options = [
    PaymentMethodOption(
      key: 'mfs',
      title: 'Mobile Finance',
      subtitle: 'bKash, Nagad, Rocket',
      icon: Icons.account_balance_wallet_outlined,
      iconColor: Color(0xFFE2136E),
      badgeBg: Color(0x1AE2136E),
    ),
    PaymentMethodOption(
      key: 'card',
      title: 'Debit / Credit Card',
      subtitle: 'Visa, Mastercard, AMEX',
      icon: Icons.credit_card_outlined,
      iconColor: Color(0xFF006B56),
      badgeBg: Color(0x1A006B56),
    ),
    PaymentMethodOption(
      key: 'bank',
      title: 'Internet Banking',
      subtitle: 'All Major Bangladeshi Banks',
      icon: Icons.account_balance_outlined,
      iconColor: Color(0xFF1976D2),
      badgeBg: Color(0x1A1976D2),
    ),
  ];

  static Future<PaymentMethodOption?> show(BuildContext context, {String? selectedKey}) {
    return showModalBottomSheet<PaymentMethodOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PaymentMethodSheet(
        selectedMethodKey: selectedKey,
        onSelectMethod: (method) => Navigator.of(context).pop(method),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEBEFEB), // var(--color-surface-container)
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomSafe),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Sheet Handle (.payment-method-handle)
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFBEC9C3), // var(--color-outline)
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Header (.payment-method-header)
          const Text(
            'Choose Payment Method',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF181C1A), // var(--color-on-surface)
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Select your preferred payment option',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3E4945), // var(--color-on-surface-variant)
            ),
          ),
          const SizedBox(height: 18),

          // 3. Payment Method List (.payment-method-list)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final opt = options[index];
              final isSelected = opt.key == selectedMethodKey;

              return InkWell(
                onTap: () => onSelectMethod(opt),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF005140)
                          : const Color(0x33BEC9C3),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Icon Badge (.payment-method-icon-badge)
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: opt.badgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          opt.icon,
                          color: opt.iconColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Info Texts (.payment-method-info)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.title,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF181C1A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt.subtitle,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6E7A75),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow (.payment-method-arrow)
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF6E7A75),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          // 4. Cancel Button (.payment-method-cancel-btn)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: Color(0xFFBEC9C3),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF181C1A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
