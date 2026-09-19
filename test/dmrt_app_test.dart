import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dmrt_online/main.dart';
import 'package:dmrt_online/features/buy_ticket/models/station_data.dart';
import 'package:dmrt_online/features/buy_ticket/buy_ticket_screen.dart';
import 'package:dmrt_online/features/buy_ticket/widgets/no_internet_dialog.dart';
import 'package:dmrt_online/features/ticket_details/ticket_details_screen.dart';
import 'package:dmrt_online/features/payment/payment_screen.dart';
import 'package:dmrt_online/features/qr_transit/qr_display_screen.dart';
import 'package:dmrt_online/features/qr_transit/widgets/ticket_select_dialog.dart';
import 'package:dmrt_online/features/auth/email_login_screen.dart';
import 'package:dmrt_online/features/auth/otp_verification_screen.dart';
import 'package:dmrt_online/features/auth/profile_setup_screen.dart';
import 'package:dmrt_online/features/profile/widgets/loading_scene_overlay.dart';
import 'package:dmrt_online/features/profile/widgets/logout_confirm_dialog.dart';
import 'package:dmrt_online/features/profile/widgets/side_menu_dialogs.dart';
import 'package:dmrt_online/shared/models/ticket_model.dart';
import 'package:dmrt_online/shared/app_gradients.dart';
import 'package:dmrt_online/shared/dynamic_ticket_notch.dart';
import 'package:dmrt_online/features/home/widgets/welcome_card.dart';
import 'package:dmrt_online/features/profile/models/user_profile_model.dart';
import 'package:dmrt_online/services/app_storage_service.dart';
import 'package:dmrt_online/services/network_service.dart';
import 'package:dmrt_online/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final sampleTicket = TicketModel(
    id: 'TKT-1001',
    origin: 'Uttara North',
    destination: 'Motijheel',
    passengerCount: 1,
    farePerPerson: 60,
    totalFare: 60,
    status: TicketStatus.available,
    purchaseTime: DateTime(2026, 9, 15, 8, 30),
  );

  final sampleHistory = [
    TicketModel(
      id: 'TKT-901',
      origin: 'Uttara North',
      destination: 'Motijheel',
      passengerCount: 1,
      farePerPerson: 60,
      totalFare: 60,
      status: TicketStatus.completed,
      purchaseTime: DateTime(2026, 9, 14, 9, 0),
      completeTime: DateTime(2026, 9, 14, 9, 45),
    ),
    TicketModel(
      id: 'TKT-902',
      origin: 'Pallabi',
      destination: 'Agargaon',
      passengerCount: 1,
      farePerPerson: 30,
      totalFare: 30,
      status: TicketStatus.expired,
      purchaseTime: DateTime(2026, 9, 13, 10, 0),
    ),
    TicketModel(
      id: 'TKT-903',
      origin: 'Mirpur 10',
      destination: 'Farmgate',
      passengerCount: 1,
      farePerPerson: 30,
      totalFare: 30,
      status: TicketStatus.refunded,
      purchaseTime: DateTime(2026, 9, 12, 11, 0),
    ),
  ];

  Future<void> seedAuthenticatedUser({
    List<TicketModel>? tickets,
    List<TicketModel>? history,
    UserProfileModel? profile,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorageService.getInstance();
    await storage.saveAuthState(
      isAuthenticated: true,
      email: 'commuter@dmrt.gov.bd',
      phoneNumber: '01316451718',
    );
    await storage.saveUserProfile(profile ?? const UserProfileModel(
      fullName: 'Dhaka Transit User',
      phoneNumber: '01316451718',
      email: 'commuter@dmrt.gov.bd',
      gender: 'Male',
      dob: '1996-01-01',
    ));
    if (tickets != null) {
      await storage.saveTickets(tickets);
    }
    if (history != null) {
      await storage.saveHistory(history);
    }
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppStorageService.resetInstanceForTesting();
  });

  group('StationData & Fare Calculations', () {
    test('calculateFare tests matching Dhaka Metro MRT rules', () {
      expect(StationData.calculateFare('Uttara North', 'Uttara Center'), 20); // gap 1
      expect(StationData.calculateFare('Uttara North', 'Pallabi'), 40); // gap 3
      expect(StationData.calculateFare('Uttara North', 'Shewrapara'), 60); // gap 7
      expect(StationData.calculateFare('Uttara North', 'Motijheel'), 100); // gap 15
      expect(StationData.calculateFare('Uttara North', 'Uttara North'), 0); // gap 0
      expect(StationData.calculateFare(null, 'Motijheel'), 0);
    });
  });

  group('HomeScreen & BuyTicketScreen Widget Tests', () {
    testWidgets('Fresh unauthenticated app boots cleanly to EmailLoginScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const DmrtApp());
      await tester.pumpAndSettle();

      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
      expect(find.text('Send Code'), findsOneWidget);
    });

    testWidgets('Authenticated HomeScreen layout smoke test with tickets', (WidgetTester tester) async {
      await seedAuthenticatedUser(tickets: [sampleTicket]);
      await tester.pumpWidget(const DmrtApp());
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeCard), findsOneWidget);
      expect(find.text('My Tickets'), findsOneWidget);
      expect(find.text('Uttara North'), findsOneWidget);
      expect(find.text('Motijheel'), findsOneWidget);
      expect(find.text('SINGLE JOURNEY'), findsOneWidget);
      expect(find.text('Use Ticket'), findsOneWidget);
    });

    testWidgets('Authenticated HomeScreen layout smoke test with zero tickets', (WidgetTester tester) async {
      await seedAuthenticatedUser(tickets: []);
      await tester.pumpWidget(const DmrtApp());
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeCard), findsOneWidget);
      expect(find.text('My Tickets'), findsOneWidget);
      expect(find.text('No active tickets available.'), findsOneWidget);
    });

    testWidgets('Navigate to BuyTicketScreen via Welcome Card Buy Ticket button', (WidgetTester tester) async {
      await seedAuthenticatedUser();
      await tester.pumpWidget(const DmrtApp());
      await tester.pumpAndSettle();

      // Tap first "Buy Ticket" button (in WelcomeCard)
      await tester.tap(find.text('Buy Ticket').first);
      await tester.pumpAndSettle();

      expect(find.text('TOTAL FARE'), findsOneWidget);
      expect(find.text('Fare Rate (per ticket)'), findsOneWidget);
      expect(find.text('Select Route'), findsOneWidget);
      expect(find.text('Select Origin'), findsOneWidget);
      expect(find.text('Select Destination'), findsOneWidget);
      expect(find.text('Number of Tickets'), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Proceed to Payment'), findsOneWidget);
    });

    testWidgets('BuyTicketScreen quantity adjustments and station picker modal', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BuyTicketScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check initial quantity is 1
      expect(find.text('1'), findsOneWidget);

      // Tap plus button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      // Tap minus button
      await tester.tap(find.byIcon(Icons.remove));
      await tester.pumpAndSettle();
      expect(find.text('1'), findsOneWidget);

      // Open Origin Station Picker
      await tester.tap(find.text('Select Origin'));
      await tester.pumpAndSettle();

      expect(find.text('Select Origin Station'), findsOneWidget);
      expect(find.text('Uttara North'), findsOneWidget);

      // Select Uttara North as Origin
      await tester.tap(find.text('Uttara North'));
      await tester.pumpAndSettle();

      // Modal dynamically updates title to "Select Destination" while staying open
      expect(find.text('Select Destination'), findsWidgets);

      // Select Mirpur 11 as Destination (gap 4 -> 40tk)
      await tester.tap(find.text('Mirpur 11'));
      await tester.pumpAndSettle();

      // Both selected -> "OK" button appears
      expect(find.text('OK'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Modal closed, Buy Ticket screen displays both stations and fare
      expect(find.text('Uttara North'), findsOneWidget);
      expect(find.text('Mirpur 11'), findsOneWidget);
    });

    testWidgets('NoInternetDialog renders 1:1 error modal and dismisses on Understood tap', (WidgetTester tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoInternetDialog(
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('You are currently offline. Tickets cannot be purchased without an active internet connection. Please connect to the internet and try again.'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('BuyTicketScreen blocks ticket purchase when offline and displays NoInternetDialog', (WidgetTester tester) async {
      NetworkService.mockIsOnline = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BuyTicketScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select stations
      await tester.tap(find.text('Select Origin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uttara North'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mirpur 11'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Tap Proceed to Payment
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Proceed to Payment'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Should display NoInternetDialog
      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      // Back on BuyTicketScreen
      expect(find.text('Proceed to Payment'), findsOneWidget);

      NetworkService.mockIsOnline = null;
    });

    testWidgets('BuyTicketScreen proceeds to payment method sheet when online', (WidgetTester tester) async {
      NetworkService.mockIsOnline = true;
      bool proceedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BuyTicketScreen(
              onProceedToPaymentWithMethod: (origin, dest, count, total, key, name) {
                proceedCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select stations
      await tester.tap(find.text('Select Origin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uttara North'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mirpur 11'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Tap Proceed to Payment
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Proceed to Payment'));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Should open Choose Payment Method sheet
      expect(find.text('Choose Payment Method'), findsOneWidget);
      expect(find.text('Mobile Finance'), findsOneWidget);

      // Select Mobile Finance
      await tester.tap(find.text('Mobile Finance'));
      await tester.pumpAndSettle();

      expect(proceedCalled, isTrue);

      NetworkService.mockIsOnline = null;
    });

    testWidgets('HistoryScreen renders tabs and cards correctly', (WidgetTester tester) async {
      await seedAuthenticatedUser(history: sampleHistory);
      await tester.pumpWidget(const DmrtApp());
      await tester.pumpAndSettle();

      // Tap History in bottom nav
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('Trip History'), findsOneWidget);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Expired'), findsWidgets);
      expect(find.text('Refunded'), findsWidgets);
      expect(find.text('Uttara North'), findsWidgets);

      // Switch to Expired tab
      await tester.tap(find.text('Expired').first);
      await tester.pumpAndSettle();
      expect(find.text('Pallabi'), findsOneWidget);

      // Switch to Refunded tab
      await tester.tap(find.text('Refunded').first);
      await tester.pumpAndSettle();
      expect(find.text('Mirpur 10'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders fields, modals and saves changes correctly', (WidgetTester tester) async {
      await seedAuthenticatedUser();
      await tester.pumpWidget(const DmrtApp());
      await tester.pumpAndSettle();

      // Navigate to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      // Verify Profile Header and Top Fields
      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Dhaka Transit User'), findsWidgets);
      expect(find.text('commuter@dmrt.gov.bd'), findsWidgets);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);

      // Open Photo Picker
      await tester.tap(find.byIcon(Icons.camera_alt));
      await tester.pumpAndSettle();

      expect(find.text('Update Profile Photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Remove Photo'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Open Side Menu Drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.text('Menu'), findsOneWidget);
      expect(find.text("Do's"), findsOneWidget);
      expect(find.text("Don'ts"), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);

      // Open and dismiss Do's dialog
      await tester.tap(find.text("Do's"));
      await tester.pumpAndSettle();

      expect(find.text("Do's Guidelines"), findsOneWidget);
      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();

      // Scroll down to see Gender, Date of Birth, and Save Changes
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);

      // Open Gender Picker
      await tester.tap(find.text('Gender'));
      await tester.pumpAndSettle();

      expect(find.text('Select Gender'), findsWidgets);
      expect(find.text('Female'), findsOneWidget);
      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();

      // Verify Gender field updated to Female
      expect(find.text('Female'), findsOneWidget);

      // Save changes (triggers 1000ms LoadingSceneOverlay)
      await tester.tap(find.text('Save Changes'));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Profile information saved successfully!'), findsOneWidget);
    });
  });

  group('Section A: Ticketing, Payment & QR Transit Flow Tests', () {
    testWidgets('TicketDetailsScreen renders 1:1 details, notch sections, and refund modal', (WidgetTester tester) async {
      bool refundCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: TicketDetailsScreen(
            ticket: sampleTicket,
            onBack: () {},
            onUseTicket: () {},
            onRefundTicket: (_) => refundCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ticket Details'), findsOneWidget);
      expect(find.text('SINGLE JOURNEY'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Uttara North'), findsOneWidget);
      expect(find.text('Motijheel'), findsOneWidget);
      expect(find.text('৳ 60'), findsOneWidget);
      expect(find.text('1 Person'), findsOneWidget);
      expect(find.text('Purchase Date & Time'), findsOneWidget);

      // Scroll down to see refund section
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.text('Refund Policy'), findsOneWidget);
      expect(find.text('Refund Ticket'), findsOneWidget);
      expect(find.text('Use Ticket'), findsOneWidget);

      // Tap Refund Ticket to open modal
      await tester.tap(find.text('Refund Ticket'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Ticket Refund'), findsOneWidget);
      expect(find.text('Refund Fee (10%)'), findsOneWidget);
      expect(find.text('৳6'), findsOneWidget);
      expect(find.text('You Will Get Back'), findsOneWidget);
      expect(find.text('৳54'), findsOneWidget);

      // Confirm Refund
      await tester.tap(find.text('Yes, Refund'));
      await tester.pumpAndSettle();

      expect(refundCalled, isTrue);
    });

    testWidgets('PaymentScreen method selector & hold-to-confirm interaction', (WidgetTester tester) async {
      TicketModel? purchasedTicket;

      await tester.pumpWidget(
        MaterialApp(
          home: PaymentScreen(
            origin: 'Uttara North',
            destination: 'Motijheel',
            passengerCount: 2,
            totalFare: 120,
            onBack: () {},
            onTicketPurchased: (t) => purchasedTicket = t,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('৳ 120'), findsOneWidget);
      expect(find.text('Mobile Finance (bKash/Nagad)'), findsOneWidget);

      // Change payment method to Debit / Credit Card
      await tester.tap(find.text('Payment Method'));
      await tester.pumpAndSettle();

      expect(find.text('Choose Payment Method'), findsOneWidget);
      expect(find.text('Debit / Credit Card'), findsOneWidget);

      await tester.tap(find.text('Debit / Credit Card'));
      await tester.pumpAndSettle();

      expect(find.text('Debit / Credit Card'), findsOneWidget);

      // Trigger Hold-To-Confirm Button
      final holdBtn = find.text('Hold to purchase');
      expect(holdBtn, findsOneWidget);

      await tester.ensureVisible(holdBtn);
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(tester.getCenter(holdBtn));
      for (int i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(purchasedTicket, isNotNull);
      expect(purchasedTicket!.origin, 'Uttara North');
      expect(purchasedTicket!.destination, 'Motijheel');
      expect(purchasedTicket!.passengerCount, 2);
      expect(purchasedTicket!.totalFare, 120);
      expect(purchasedTicket!.paymentMethod, 'Debit / Credit Card');
    });

    testWidgets('QrDisplayScreen permanent active state and entry/exit gate flow', (WidgetTester tester) async {
      bool entryCalled = false;
      bool tripCompleted = false;

      final availableTicket = sampleTicket.copyWith(status: TicketStatus.available);

      await tester.pumpWidget(
        MaterialApp(
          home: QrDisplayScreen(
            ticket: availableTicket,
            onBack: () {},
            onPassEntryBarrier: () => entryCalled = true,
            onCompleteTrip: () => tripCompleted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Show at Reader'), findsOneWidget);
      expect(find.text('Active Ticket QR • Ready to Scan'), findsOneWidget);
      expect(find.text('Tap to Pass Entry Barrier'), findsOneWidget);
      expect(find.text('Uttara North'), findsOneWidget);
      expect(find.text('Motijheel'), findsOneWidget);

      // Pass entry barrier (with loading delay)
      await tester.tap(find.text('Tap to Pass Entry Barrier'));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      expect(entryCalled, isTrue);

      // Test Riding Exit State
      final ridingTicket = sampleTicket.copyWith(
        status: TicketStatus.riding,
        exitQrActive: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QrDisplayScreen(
            ticket: ridingTicket,
            onBack: () {},
            onPassEntryBarrier: () {},
            onCompleteTrip: () => tripCompleted = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Show at Exit Reader'), findsOneWidget);
      expect(find.text('Tap to Pass Exit Barrier'), findsOneWidget);

      // Complete Trip
      await tester.tap(find.text('Tap to Pass Exit Barrier'));
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      expect(tripCompleted, isTrue);
    });

    testWidgets('TicketSelectDialog displays ticket options and selects correctly', (WidgetTester tester) async {
      final ticket1 = sampleTicket.copyWith(id: 'TKT-1001', origin: 'Uttara North', destination: 'Motijheel');
      final ticket2 = sampleTicket.copyWith(id: 'TKT-1002', origin: 'Farmgate', destination: 'Secretariat');

      TicketModel? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketSelectDialog(
              tickets: [ticket1, ticket2],
              onSelectTicket: (t) => selected = t,
              onCancel: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Ticket'), findsOneWidget);
      expect(find.text('Uttara North'), findsOneWidget);
      expect(find.text('Farmgate'), findsOneWidget);

      await tester.tap(find.text('Farmgate'));
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.id, 'TKT-1002');
    });
  });

  group('Side Menu Dialogs & Overlays Tests', () {
    testWidgets('DosGuidelinesDialog renders and dismisses on Got It tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => DosGuidelinesDialog.show(ctx),
                child: const Text('Open Dos'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dos'));
      await tester.pumpAndSettle();

      expect(find.text("Do's Guidelines"), findsOneWidget);
      expect(find.text('Stand behind the yellow safety line on platforms while waiting for trains.'), findsOneWidget);

      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();
      expect(find.text("Do's Guidelines"), findsNothing);
    });

    testWidgets('DontsGuidelinesDialog renders and dismisses on Got It tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => DontsGuidelinesDialog.show(ctx),
                child: const Text('Open Donts'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Donts'));
      await tester.pumpAndSettle();

      expect(find.text("Don'ts Guidelines"), findsOneWidget);
      expect(find.text('Do not smoke, consume tobacco, or use e-cigarettes anywhere in metro premises.'), findsOneWidget);

      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();
      expect(find.text("Don'ts Guidelines"), findsNothing);
    });

    testWidgets('MetroMapDialog renders MRT Line 6 station list', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => MetroMapDialog.show(ctx),
                child: const Text('Open Map'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Map'));
      await tester.pumpAndSettle();

      expect(find.text('MRT Line 6 Map'), findsOneWidget);
      expect(find.text('MRT Line 6 • Uttara North ↔ Motijheel'), findsOneWidget);
      expect(find.text('Uttara North'), findsOneWidget);
      expect(find.text('Motijheel'), findsOneWidget);

      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();
      expect(find.text('MRT Line 6 Map'), findsNothing);
    });

    testWidgets('PermissionsDialog renders permissions list with allowed tags', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => PermissionsDialog.show(ctx),
                child: const Text('Open Permissions'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Permissions'));
      await tester.pumpAndSettle();

      expect(find.text('App Permissions'), findsOneWidget);
      expect(find.text('Camera Access'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Local Storage'), findsOneWidget);
      expect(find.text('Allowed'), findsNWidgets(3));

      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();
      expect(find.text('App Permissions'), findsNothing);
    });

    testWidgets('SupportRequestDialog renders support hotlines and email', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SupportRequestDialog.show(ctx),
                child: const Text('Open Support'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Support'));
      await tester.pumpAndSettle();

      expect(find.text('Support Center'), findsOneWidget);
      expect(find.text('16100 / 09612-016100'), findsOneWidget);
      expect(find.text('support@dmtcl.gov.bd'), findsOneWidget);

      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();
      expect(find.text('Support Center'), findsNothing);
    });

    testWidgets('PoliciesDialog renders fare and refund policies', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => PoliciesDialog.show(ctx),
                child: const Text('Open Policies'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Policies'));
      await tester.pumpAndSettle();

      expect(find.text('Policies & Terms'), findsOneWidget);
      expect(find.text('Ticketing & Fare Rules'), findsOneWidget);
      expect(find.text('Refund Policy'), findsOneWidget);

      await tester.tap(find.text('Got It'));
      await tester.pumpAndSettle();
      expect(find.text('Policies & Terms'), findsNothing);
    });

    testWidgets('LogoutConfirmDialog confirms and triggers logout', (WidgetTester tester) async {
      bool? logoutConfirmed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () async {
                  logoutConfirmed = await LogoutConfirmDialog.show(ctx);
                },
                child: const Text('Open Logout'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Logout'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(logoutConfirmed, isTrue);
    });

    testWidgets('LoadingSceneOverlay displays message and dismisses on tap', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => LoadingSceneOverlay.show(
                  ctx,
                  message: 'Authenticating...',
                ),
                child: const Text('Open Loading'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Loading'));
      await tester.pump();

      expect(find.text('Authenticating...'), findsOneWidget);

      await tester.tap(find.byType(LoadingSceneOverlay));
      await tester.pumpAndSettle();

      expect(find.text('Authenticating...'), findsNothing);
    });
  });

  group('Authentication Flow Tests', () {
    testWidgets('EmailLoginScreen validates email and triggers onNext with valid email', (WidgetTester tester) async {
      String? submittedEmail;

      await tester.pumpWidget(
        MaterialApp(
          home: EmailLoginScreen(
            onNext: (email) => submittedEmail = email,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextField), 'invalid-email');
      await tester.pumpAndSettle();

      // Enter valid email
      await tester.enterText(find.byType(TextField), 'user@example.com');
      await tester.pumpAndSettle();

      // Tap Send Code button
      await tester.tap(find.text('Send Code'));
      await tester.pumpAndSettle();

      expect(submittedEmail, 'user@example.com');
    });

    testWidgets('OtpVerificationScreen verifies with bypass code 000000 and triggers onVerified', (WidgetTester tester) async {
      bool verifiedFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            email: 'user@example.com',
            onBack: () {},
            onVerified: () => verifiedFired = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.text('Enter the 6-digit code sent to\nuser@example.com'), findsOneWidget);

      // Enter 6 zeros
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));

      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '0');
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Wait for success animation and timeout callback
      await tester.pump(const Duration(milliseconds: 1200));

      expect(verifiedFired, isTrue);
    });

    testWidgets('ProfileSetupScreen allows entering name, skipping, or completing profile', (WidgetTester tester) async {
      String? completedName;
      bool skipFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileSetupScreen(
            onComplete: (name, avatar) => completedName = name,
            onSkip: () => skipFired = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Set up your profile'), findsOneWidget);

      // Enter full name
      await tester.enterText(find.byType(TextField), 'Fahim Ahmed');
      await tester.pumpAndSettle();

      // Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(completedName, 'Fahim Ahmed');
      expect(skipFired, isFalse);
    });

    testWidgets('Full End-to-End Email Login, OTP 000000, Profile Setup, and Logout Flow', (WidgetTester tester) async {
      await tester.pumpWidget(const DmrtApp());
      await tester.pumpAndSettle();

      // 1. Clean launch starts directly on EmailLoginScreen
      expect(find.text('Enter your email address'), findsOneWidget);

      // 2. Enter valid Email
      await tester.enterText(find.byType(TextField), 'farhan@dmrt.gov.bd');
      await tester.pumpAndSettle();

      // 3. Tap Send Code
      await tester.tap(find.text('Send Code'));
      await tester.pumpAndSettle();
      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.text('Enter the 6-digit code sent to\nfarhan@dmrt.gov.bd'), findsOneWidget);

      // 4. Enter test OTP 000000
      final otpFields = find.byType(TextField);
      expect(otpFields, findsNWidgets(6));
      for (int i = 0; i < 6; i++) {
        await tester.enterText(otpFields.at(i), '0');
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();

      // 5. Profile Setup Screen appears
      expect(find.text('Set up your profile'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Farhan Kabir');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // 6. Landed on Home Screen with updated user greeting
      expect(find.textContaining('Farhan'), findsWidgets);

      // 7. Go to Profile screen and verify updated profile
      await tester.tap(find.byIcon(Icons.person).first);
      await tester.pumpAndSettle();
      expect(find.text('Farhan Kabir'), findsWidgets);
      expect(find.text('farhan@dmrt.gov.bd'), findsWidgets);

      // 8. Open Side Menu and Trigger Logout
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).last, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Confirm Logout modal appears
      expect(find.text('Confirm Logout'), findsOneWidget);
      await tester.tap(find.text('Logout').last);
      await tester.pumpAndSettle();

      // 9. Successfully logged out and redirected to Email Login
      expect(find.text('Enter your email address'), findsOneWidget);
    });
  });

  group('DynamicTicketNotchCutout & Gradient Blending Tests', () {
    test('AppGradients.getGradientColorAt matches 1:1 with Web Prototype formula', () {
      expect(AppGradients.getGradientColorAt(0.0), const Color(0xFF188674));
      expect(AppGradients.getGradientColorAt(1.0), const Color(0xFF188674));
      expect(AppGradients.getGradientColorAt(15.0), const Color(0xFF9FD1C6));
      expect(AppGradients.getGradientColorAt(90.0), const Color(0xFFFFFFFF));
      expect(AppGradients.getGradientColorAt(100.0), const Color(0xFFFFFFFF));

      // Test midpoint between 1% and 15% (8%)
      final mid1 = AppGradients.getGradientColorAt(8.0);
      expect((mid1.a * 255).round(), 255);
      expect((mid1.r * 255).round(), inInclusiveRange(24, 159));
      expect((mid1.g * 255).round(), inInclusiveRange(134, 209));
      expect((mid1.b * 255).round(), inInclusiveRange(116, 198));

      // Test midpoint between 15% and 90% (52.5%)
      final mid2 = AppGradients.getGradientColorAt(52.5);
      expect((mid2.a * 255).round(), 255);
      expect((mid2.r * 255).round(), inInclusiveRange(159, 255));
      expect((mid2.g * 255).round(), inInclusiveRange(209, 255));
      expect((mid2.b * 255).round(), inInclusiveRange(198, 255));
    });

    testWidgets('DynamicTicketNotchCutout renders left and right notches correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.pageGradient,
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    DynamicTicketNotchCutout(isLeft: true),
                    DynamicTicketNotchCutout(isLeft: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DynamicTicketNotchCutout), findsNWidgets(2));
    });
  });

  group('Ticket Prioritization, Flow Matrix & Navigation Tests', () {
    testWidgets('Ticket Card Click Matrix: available goes to details, riding goes to QR', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await seedAuthenticatedUser(tickets: [sampleTicket]);
      await tester.pumpWidget(const DmrtApp());
      await tester.pumpAndSettle();

      // 1. Initial state has 1 available ticket: tap card body -> opens TicketDetailsScreen
      await tester.tap(find.text('Uttara North').first);
      await tester.pumpAndSettle();

      expect(find.text('Ticket Details'), findsOneWidget);
      expect(find.text('SINGLE JOURNEY'), findsWidgets);

      // Go back to home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('My Tickets'), findsOneWidget);

      // 2. Use ticket -> triggers loading overlay and opens active QR screen directly
      await tester.tap(find.text('Use Ticket'));
      await tester.pump(); // Loading scene start
      await tester.pump(const Duration(milliseconds: 1100)); // Loading scene finish
      await tester.pumpAndSettle();

      expect(find.text('Show at Reader'), findsOneWidget);
      expect(find.text('Tap to Pass Entry Barrier'), findsOneWidget);

      // 3. Tap to Pass Entry Barrier -> becomes riding
      await tester.tap(find.text('Tap to Pass Entry Barrier'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      expect(find.text('Show at Exit Reader'), findsOneWidget);
      expect(find.text('Tap to Pass Exit Barrier'), findsOneWidget);

      // 4. Back to Home: verify ticket card is now "Riding"
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Riding'), findsOneWidget);
      expect(find.text('Current Trip'), findsOneWidget);

      // 5. Tapping riding card body directly opens QR view (not details)
      await tester.tap(find.text('Uttara North').first);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Show at Exit Reader'), findsOneWidget);
    });

    testWidgets('Bottom Nav Bar Scan FAB respects riding and available states', (WidgetTester tester) async {
      await seedAuthenticatedUser(tickets: [sampleTicket]);
      await tester.pumpWidget(const DmrtApp());
      await tester.pump(const Duration(milliseconds: 300));

      // Initial state: exactly 1 available ticket -> pressing center scan button opens QR view directly with loading
      await tester.tap(find.byIcon(Icons.qr_code_scanner).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      expect(find.text('Show at Reader'), findsOneWidget);
      expect(find.text('Tap to Pass Entry Barrier'), findsOneWidget);
    });

    testWidgets('PopScope back navigation unwinds active screens back to Home', (WidgetTester tester) async {
      await seedAuthenticatedUser();
      await tester.pumpWidget(const DmrtApp());
      await tester.pumpAndSettle();

      // Navigate to Buy Ticket (Nav Index 1)
      await tester.tap(find.text('Buy Ticket').first);
      await tester.pumpAndSettle();
      expect(find.text('TOTAL FARE'), findsOneWidget);

      // Trigger back button (system back pop)
      final dynamic widgetsAppState = tester.state(find.byType(WidgetsApp));
      await widgetsAppState.didPopRoute();
      await tester.pumpAndSettle();

      // Returns to Home
      expect(find.text('My Tickets'), findsOneWidget);
    });

    testWidgets('Tapping ticket card body navigates to Ticket Details Screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await seedAuthenticatedUser(tickets: [sampleTicket]);
      await tester.pumpWidget(const DmrtApp());
      await tester.pumpAndSettle();

      // Initial state has 1 ticket on Home
      expect(find.text('Refund'), findsOneWidget);

      // Tap ticket card body (e.g. Origin station name)
      await tester.tap(find.text('Uttara North').first);
      await tester.pumpAndSettle();

      // Should open Ticket Details Screen
      expect(find.text('Ticket Details'), findsOneWidget);
      expect(find.text('Refund Ticket'), findsOneWidget);

      // Back to Home
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('My Tickets'), findsOneWidget);
    });

    testWidgets('Locked ticket details screen displays locked indicator, badge, disabled action, and functional refund', (WidgetTester tester) async {
      final availableTicket = TicketModel(
        id: 'DMRT-1002',
        origin: 'Uttara Center',
        destination: 'Mirpur 10',
        passengerCount: 1,
        farePerPerson: 30,
        totalFare: 30,
        purchaseTime: DateTime.now(),
        status: TicketStatus.available,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TicketDetailsScreen(
            ticket: availableTicket,
            isLocked: true,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifications for locked mode
      expect(find.text('Ticket Details'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('Locked (Another Trip in Progress)'), findsOneWidget);
      expect(find.text('Refund Ticket'), findsOneWidget);
    });
  });

  group('AppStorageService & Persistence Tests', () {
    test('UserProfileModel, TicketModel serialization and persistence round-trip', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await AppStorageService.getInstance();

      final profile = const UserProfileModel(
        id: 'pass-uuid-1234',
        authId: 'auth-uuid-5678',
        fullName: 'Test Commuter',
        email: 'commuter@dmrt.gov.bd',
        phoneNumber: '01811223344',
        gender: 'female',
        dob: '1995-05-15',
        avatarUrl: 'data:image/jpeg;base64,dGVzdA==',
      );

      await storage.saveUserProfile(profile);
      final loadedProfile = storage.loadUserProfile();
      expect(loadedProfile, isNotNull);
      expect(loadedProfile!.id, 'pass-uuid-1234');
      expect(loadedProfile.authId, 'auth-uuid-5678');
      expect(loadedProfile.fullName, 'Test Commuter');
      expect(loadedProfile.email, 'commuter@dmrt.gov.bd');
      expect(loadedProfile.phoneNumber, '01811223344');
      expect(loadedProfile.gender, 'female');
      expect(loadedProfile.avatarUrl, 'data:image/jpeg;base64,dGVzdA==');

      final testTickets = [sampleTicket];
      await storage.saveTickets(testTickets);
      final loadedTickets = storage.loadTickets();
      expect(loadedTickets, isNotNull);
      expect(loadedTickets!.length, testTickets.length);
      expect(loadedTickets.first.id, testTickets.first.id);
      expect(loadedTickets.first.origin, testTickets.first.origin);
      expect(loadedTickets.first.destination, testTickets.first.destination);

      final testHistory = sampleHistory;
      await storage.saveHistory(testHistory);
      final loadedHistory = storage.loadHistory();
      expect(loadedHistory, isNotNull);
      expect(loadedHistory!.length, testHistory.length);
      expect(loadedHistory.first.id, testHistory.first.id);
      expect(loadedHistory.first.status, testHistory.first.status);

      await storage.saveAuthState(
        isAuthenticated: true,
        email: 'commuter@dmrt.gov.bd',
        phoneNumber: '01811223344',
      );
      expect(storage.loadIsAuthenticated(), isTrue);
      expect(storage.loadAuthEmail(), 'commuter@dmrt.gov.bd');
      expect(storage.loadAuthPhone(), '01811223344');
    });

    testWidgets('OtpVerificationScreen allows typing, invalid error feedback, and digit replacement', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OtpVerificationScreen(
            email: 'user@example.com',
            onBack: () {},
            onVerified: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(6));

      // Enter invalid OTP 123456
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '${i + 1}');
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();

      // Check error message appears
      expect(find.text('Invalid OTP code. Please check your email inbox.'), findsOneWidget);

      // Tap on the first box and change it to 0
      await tester.tap(textFields.at(0));
      await tester.enterText(textFields.at(0), '0');
      await tester.pumpAndSettle();

      // Error message should clear on editing
      expect(find.text('Invalid OTP code. Please check your email inbox.'), findsNothing);
    });
  });

  group('SupabaseService & Offline Resilience Verification', () {
    test('SupabaseService singleton exists and methods gracefully handle offline state', () async {
      final service = SupabaseService.instance;
      expect(service, isNotNull);

      // Verify OTP verification with test code 000000
      final verifyEmailRes = await service.verifyEmailOtp(email: 'test@dmrt.gov.bd', otp: '000000');
      expect(verifyEmailRes['verified'], isTrue);

      final verifyPhoneRes = await service.verifyOtp(phoneNumber: '01700000000', otp: '000000');
      expect(verifyPhoneRes != null && verifyPhoneRes['verified'] == true, isTrue);

      // Verify sendEmailOtp returns success structure
      final emailSendRes = await service.sendEmailOtp('test@dmrt.gov.bd');
      expect(emailSendRes['success'], isTrue);

      // Verify requestOtp returns valid map structure
      final otpRes = await service.requestOtp('01700000000');
      expect(otpRes, isNotNull);
      expect(otpRes!['otp'], '000000');

      // Uninitialized offline fallbacks
      final profile = await service.getOrCreatePassengerByEmail(email: 'test@dmrt.gov.bd');
      expect(profile, isNull);

      final liveTickets = await service.fetchLiveTickets(email: 'test@dmrt.gov.bd');
      expect(liveTickets, isEmpty);

      final tripHistory = await service.fetchTripHistory(email: 'test@dmrt.gov.bd');
      expect(tripHistory, isEmpty);

      final buyResult = await service.buyTicket(
        email: 'test@dmrt.gov.bd',
        origin: 'Uttara North',
        destination: 'Motijheel',
        passengerCount: 2,
        paymentMethod: 'bKash',
      );
      expect(buyResult, isNull);

      final entryResult = await service.passEntryBarrier(ticketId: 'TKT-1', email: 'test@dmrt.gov.bd');
      expect(entryResult, isFalse);

      final exitResult = await service.passExitBarrier(ticketId: 'TKT-1', email: 'test@dmrt.gov.bd');
      expect(exitResult, isFalse);

      final refundResult = await service.requestRefund(ticketId: 'TKT-1', email: 'test@dmrt.gov.bd');
      expect(refundResult, isFalse);
    });

    test('TicketModel fare calculation and copyWith state transitions', () {
      final ticket = TicketModel(
        id: 'TKT-TEST-001',
        origin: 'Uttara North',
        destination: 'Motijheel',
        passengerCount: 3,
        farePerPerson: 100,
        totalFare: 300,
        purchaseTime: DateTime(2026, 9, 19, 10, 0),
        status: TicketStatus.available,
      );

      expect(ticket.totalFare, 300);
      expect(ticket.passengerCount, 3);
      expect(ticket.status, TicketStatus.available);

      // Transition to RIDING
      final riding = ticket.copyWith(status: TicketStatus.riding, exitQrActive: false);
      expect(riding.status, TicketStatus.riding);
      expect(riding.exitQrActive, isFalse);

      // Transition to COMPLETED
      final completed = riding.copyWith(status: TicketStatus.completed, completeTime: DateTime(2026, 9, 19, 10, 45));
      expect(completed.status, TicketStatus.completed);
      expect(completed.completeTime, isNotNull);
    });

    test('NetworkService returns mock value and handles offline state', () async {
      NetworkService.mockIsOnline = true;
      expect(await NetworkService.hasInternetConnection(), isTrue);

      NetworkService.mockIsOnline = false;
      expect(await NetworkService.hasInternetConnection(), isFalse);

      NetworkService.mockIsOnline = null;
    });
  });
}
