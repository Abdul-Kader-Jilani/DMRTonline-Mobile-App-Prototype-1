import 'package:flutter/material.dart';

/// 1:1 Strict Translations of CSS gradients from Web Prototype/index.html
class AppGradients {
  /// 1:1 Matching #view-home, #view-buy, #view-history, #view-profile, #view-details, #view-payment, #view-qr
  /// CSS: linear-gradient(180deg, #188674 0%, #188674 1%, #9fd1c6 15%, #ffffff 90%) !important
  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.01, 0.15, 0.90],
    colors: [
      Color(0xFF188674),
      Color(0xFF188674),
      Color(0xFF9FD1C6),
      Color(0xFFFFFFFF),
    ],
  );

  /// 1:1 Matching .auth-page for #view-auth-phone, #view-auth-otp, #view-auth-profile-setup
  /// CSS: linear-gradient(180deg, #188674 0%, #188674 1%, #9fd1c6 25%, #d9e8e5 100%) !important
  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.01, 0.25, 1.0],
    colors: [
      Color(0xFF188674),
      Color(0xFF188674),
      Color(0xFF9FD1C6),
      Color(0xFFD9E8E5),
    ],
  );

  /// 1:1 Port of getGradientColorAt(pct) from Web Prototype/index.html
  /// Calculates the exact background color at vertical percentage [pct] (0% - 100%)
  static Color getGradientColorAt(double pct) {
    if (pct <= 1.0) return const Color(0xFF188674);
    if (pct <= 15.0) {
      final t = (pct - 1.0) / 14.0;
      final r = (24 + (159 - 24) * t).round();
      final g = (134 + (209 - 134) * t).round();
      final b = (116 + (198 - 116) * t).round();
      return Color.fromARGB(255, r, g, b);
    } else if (pct < 90.0) {
      final t = (pct - 15.0) / 75.0;
      final r = (159 + (255 - 159) * t).round();
      final g = (209 + (255 - 209) * t).round();
      final b = (198 + (255 - 198) * t).round();
      return Color.fromARGB(255, r, g, b);
    }
    return const Color(0xFFFFFFFF);
  }
}

