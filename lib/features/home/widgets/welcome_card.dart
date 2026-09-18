import 'dart:convert';
import 'package:flutter/material.dart';

/// 1:1 Pure recreation of `.welcome-card` from Web Prototype/index.html
class WelcomeCard extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback? onBuyTicket;
  final VoidCallback? onProfileTap;

  const WelcomeCard({
    super.key,
    this.greeting = 'Good Morning, Dhaka User',
    this.subtitle = 'Ready for your ride?',
    this.avatarUrl,
    this.onBuyTicket,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    // Position comfortably just under dynamic island / status bar
    final effectiveTopPadding = topSafe > 0 ? (topSafe + 4.0) : 48.0;

    // Exact aspect ratio from CSS: aspect-ratio: 1536 / 1024 (1.5)
    return AspectRatio(
      aspectRatio: 1536 / 1024,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF006B56), // var(--color-primary-container)
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFB51B00), // var(--color-secondary)
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x40003328), // 0 8px 24px rgba(0, 51, 40, 0.25)
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
          image: DecorationImage(
            image: AssetImage('assets/dmrt/new_home_vector.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, effectiveTopPadding, 16, 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Brand Logo + DMRTonline Title Image + User Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo + Stylized Title Image Left
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/dmrt/logo.png',
                        height: 36,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Image.asset(
                        'assets/dmrt/title_logo.png',
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),

                  // Avatar Right
                  GestureDetector(
                    onTap: onProfileTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF006B56),
                        border: Border.all(
                          color: const Color(0xFF005140),
                          width: 2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _buildAvatarContent(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Greeting + "Buy Ticket" Button Row (Right under logo & avatar)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Greeting & Subtitle
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF181C1A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF1F2937),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Buy Ticket Pill Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onBuyTicket,
                      borderRadius: BorderRadius.circular(999),
                      child: Ink(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0B9175),
                              Color(0xFF005140),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0x73BEC9C3), // rgba(190, 201, 195, 0.45)
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33005140), // 0 4px 12px rgba(0, 81, 64, 0.2)
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.confirmation_number_outlined,
                              size: 15,
                              color: Colors.white,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Buy Ticket',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
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

  Widget _buildAvatarContent() {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('data:image') || !avatarUrl!.startsWith('http')) {
        try {
          String cleanBase64 = avatarUrl!;
          if (cleanBase64.contains(',')) {
            cleanBase64 = cleanBase64.split(',').last;
          }
          final bytes = base64Decode(cleanBase64);
          return Image.memory(
            bytes,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
          );
        } catch (_) {
          return _buildFallbackIcon();
        }
      } else {
        return Image.network(
          avatarUrl!,
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
        );
      }
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return const Center(
      child: Icon(
        Icons.person,
        size: 20,
        color: Color(0xFF94E8CE), // var(--color-on-primary-container)
      ),
    );
  }
}
