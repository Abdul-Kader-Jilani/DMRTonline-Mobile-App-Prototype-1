import 'package:flutter/material.dart';
import '../../buy_ticket/models/station_data.dart';

/// Base Modal Sheet Container for all Side Menu Information Dialogs
class _BaseInfoDialog extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _BaseInfoDialog({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 340,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.80,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF181C1A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22, color: Color(0xFF6E7A75)),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE0E3E0)),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: child,
                ),
              ),

              // Bottom Close Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005140),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                    child: const Text(
                      'Got It',
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
        ),
      ),
    );
  }
}

/// 1:1 Do's Guidelines Modal Dialog
class DosGuidelinesDialog extends StatelessWidget {
  const DosGuidelinesDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DosGuidelines',
      barrierColor: const Color(0x73000000),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => const DosGuidelinesDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dosList = [
      'Stand behind the yellow safety line on platforms while waiting for trains.',
      'Allow arriving passengers to alight completely before boarding the train.',
      'Give priority seating to the elderly, pregnant women, and passengers with disabilities.',
      'Keep your ticket QR code or MRT Pass ready before approaching the gate readers.',
      'Hold onto handrails and straps firmly when standing inside moving trains.',
      'Maintain queue discipline when boarding trains, escalators, and ticketing gates.',
    ];

    return _BaseInfoDialog(
      title: "Do's Guidelines",
      icon: Icons.check_circle,
      iconColor: const Color(0xFF006B56),
      child: Column(
        children: dosList.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF006B56),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF181C1A),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 1:1 Don'ts Guidelines Modal Dialog
class DontsGuidelinesDialog extends StatelessWidget {
  const DontsGuidelinesDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DontsGuidelines',
      barrierColor: const Color(0x73000000),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => const DontsGuidelinesDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dontsList = [
      'Do not smoke, consume tobacco, or use e-cigarettes anywhere in metro premises.',
      'Do not eat, drink, or chew gum inside train coaches and station paid areas.',
      'Do not lean against or attempt to force open automated train doors.',
      'Do not litter or cause damage/vandalism to station facilities and trains.',
      'Do not carry dangerous, flammable, or oversized hazardous items.',
      'Do not sit on the floor of train coaches or block vestibule walkways.',
    ];

    return _BaseInfoDialog(
      title: "Don'ts Guidelines",
      icon: Icons.cancel,
      iconColor: const Color(0xFFBA1A1A),
      child: Column(
        children: dontsList.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.highlight_off,
                  color: Color(0xFFBA1A1A),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF181C1A),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 1:1 Dhaka Metro Route Map Modal Dialog
class MetroMapDialog extends StatelessWidget {
  const MetroMapDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'MetroMap',
      barrierColor: const Color(0x73000000),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => const MetroMapDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BaseInfoDialog(
      title: 'MRT Line 6 Map',
      icon: Icons.map,
      iconColor: const Color(0xFF005140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x1A006B56),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.directions_subway, size: 18, color: Color(0xFF006B56)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'MRT Line 6 • Uttara North ↔ Motijheel',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF006B56),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: StationData.stations.length,
            itemBuilder: (context, index) {
              final s = StationData.stations[index];
              final isTerminal = index == 0 || index == StationData.stations.length - 1;
              return Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (index > 0)
                          Positioned(
                            top: 0,
                            bottom: 18,
                            width: 3,
                            child: Container(color: const Color(0xFF006B56)),
                          ),
                        if (index < StationData.stations.length - 1)
                          Positioned(
                            top: 18,
                            bottom: 0,
                            width: 3,
                            child: Container(color: const Color(0xFF006B56)),
                          ),
                        Container(
                          width: isTerminal ? 12 : 8,
                          height: isTerminal ? 12 : 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isTerminal ? const Color(0xFF005140) : Colors.white,
                            border: Border.all(
                              color: const Color(0xFF005140),
                              width: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            s.nameEn,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: isTerminal ? FontWeight.w700 : FontWeight.w500,
                              color: const Color(0xFF181C1A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          s.nameBn,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: Color(0xFF6E7A75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 1:1 Permissions Status Dialog
class PermissionsDialog extends StatelessWidget {
  const PermissionsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Permissions',
      barrierColor: const Color(0x73000000),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => const PermissionsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = [
      {
        'title': 'Camera Access',
        'desc': 'Required for scanning turnstile gate QR codes and profile photo capture.',
        'granted': true,
        'icon': Icons.camera_alt,
      },
      {
        'title': 'Notifications',
        'desc': 'Sends real-time journey status, ticket expiry alerts, and emergency updates.',
        'granted': true,
        'icon': Icons.notifications_active,
      },
      {
        'title': 'Local Storage',
        'desc': 'Used for offline ticket caching and local passenger profile persistence.',
        'granted': true,
        'icon': Icons.folder_shared,
      },
    ];

    return _BaseInfoDialog(
      title: 'App Permissions',
      icon: Icons.security,
      iconColor: const Color(0xFF1976D2),
      child: Column(
        children: permissions.map((p) {
          final granted = p['granted'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(p['icon'] as IconData, size: 22, color: const Color(0xFF006B56)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p['title'] as String,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF181C1A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: granted ? const Color(0x1A006B56) : const Color(0x1ABA1A1A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              granted ? 'Allowed' : 'Denied',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: granted ? const Color(0xFF006B56) : const Color(0xFFBA1A1A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p['desc'] as String,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFF6E7A75),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 1:1 Support Request Modal Dialog
class SupportRequestDialog extends StatelessWidget {
  const SupportRequestDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SupportRequest',
      barrierColor: const Color(0x73000000),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => const SupportRequestDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BaseInfoDialog(
      title: 'Support Center',
      icon: Icons.contact_support,
      iconColor: const Color(0xFFE2136E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need help with your tickets or journey?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF181C1A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Our 24/7 Dhaka Metro passenger support desk is ready to assist you.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF6E7A75),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1A006B56),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.phone_in_talk, color: Color(0xFF006B56), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DMRT Hotline',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFF006B56),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '16100 / 09612-016100',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF181C1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0x1A1976D2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.email, color: Color(0xFF1976D2), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email Support',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'support@dmtcl.gov.bd',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF181C1A),
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
    );
  }
}

/// 1:1 Policies & Terms Modal Dialog
class PoliciesDialog extends StatelessWidget {
  const PoliciesDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Policies',
      barrierColor: const Color(0x73000000),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => const PoliciesDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BaseInfoDialog(
      title: 'Policies & Terms',
      icon: Icons.policy,
      iconColor: const Color(0xFF005140),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ticketing & Fare Rules',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF181C1A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '• Single Journey tickets are valid for 24 hours from purchase time.\n• Commuters have a maximum of 60 minutes to complete their trip after entering the station gate.\n• Exceeding 60 minutes or wrong station exits require station officer clearance.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF3E4945),
              height: 1.4,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Refund Policy',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF181C1A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '• Unused active tickets can be refunded before the 24-hour expiry.\n• A standard 10% administrative fee is deducted; the remaining 90% is credited instantly back to the commuter wallet.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF3E4945),
              height: 1.4,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Privacy & Security',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF181C1A),
            ),
          ),
          SizedBox(height: 4),
          Text(
            '• Passenger phone numbers and travel history are stored securely and encrypted.\n• DMRT complies with national data privacy regulations.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF3E4945),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
