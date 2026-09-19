import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to check real-time device internet connectivity across Mobile, Web, and Desktop
class NetworkService {
  /// Mock hook for widget & unit testing
  static bool? mockIsOnline;

  /// Checks if the device has an active, working internet connection
  static Future<bool> hasInternetConnection() async {
    // If a mock value is set (e.g. for testing), return it immediately
    if (mockIsOnline != null) {
      return mockIsOnline!;
    }

    try {
      // Fast lightweight query to verify active connectivity with Supabase backend
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('routes')
          .select('id')
          .limit(1)
          .timeout(const Duration(milliseconds: 2500));
      return res.isNotEmpty;
    } catch (e) {
      debugPrint('[NetworkService] Connectivity ping check failed: $e');
      return false;
    }
  }
}
