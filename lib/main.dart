import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';
import 'shared/device_simulator_overlay.dart';
import 'shared/scaled_viewport_wrapper.dart';

import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const DmrtApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class DmrtApp extends StatelessWidget {
  const DmrtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DMRT Online',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005140),
          primary: const Color(0xFF005140),
        ),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      builder: (context, child) {
        if (kIsWeb) {
          return DeviceSimulatorOverlay(
            child: ScaledViewportWrapper(
              baseWidth: 360.0,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        }
        return child ?? const SizedBox.shrink();
      },
      home: const HomeScreen(),
    );
  }
}



