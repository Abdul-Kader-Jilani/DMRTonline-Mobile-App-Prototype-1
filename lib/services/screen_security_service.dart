import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to toggle window security (FLAG_SECURE) to block screenshots and screen recordings
class ScreenSecurityService {
  static const MethodChannel _channel = MethodChannel('dmrt.security/screen');

  /// Enables screenshot & screen recording blocking (Android FLAG_SECURE)
  static Future<void> enableSecureScreen() async {
    try {
      if (!kIsWeb) {
        await _channel.invokeMethod('enableSecure');
        debugPrint('[ScreenSecurityService] Screen security ENABLED (FLAG_SECURE active)');
      }
    } catch (e) {
      debugPrint('[ScreenSecurityService] enableSecureScreen warning: $e');
    }
  }

  /// Disables screenshot & screen recording blocking
  static Future<void> disableSecureScreen() async {
    try {
      if (!kIsWeb) {
        await _channel.invokeMethod('disableSecure');
        debugPrint('[ScreenSecurityService] Screen security DISABLED (FLAG_SECURE cleared)');
      }
    } catch (e) {
      debugPrint('[ScreenSecurityService] disableSecureScreen warning: $e');
    }
  }
}
