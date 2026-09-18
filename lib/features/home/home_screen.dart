import 'package:flutter/material.dart';
import '../../services/app_storage_service.dart';
import '../../services/supabase_service.dart';
import '../../shared/app_gradients.dart';
import '../../shared/bottom_nav_bar.dart';
import '../../shared/models/ticket_model.dart';
import '../../shared/widgets/app_toast.dart';
import '../auth/otp_verification_screen.dart';
import '../auth/phone_login_screen.dart';
import '../auth/profile_setup_screen.dart';
import '../buy_ticket/buy_ticket_screen.dart';
import '../history/history_screen.dart';
import '../history/models/history_ticket_model.dart';
import '../payment/payment_screen.dart';
import '../profile/models/user_profile_model.dart';
import '../profile/profile_screen.dart';
import '../profile/widgets/loading_scene_overlay.dart';
import '../qr_transit/qr_display_screen.dart';
import '../qr_transit/widgets/ticket_select_dialog.dart';
import '../ticket_details/ticket_details_screen.dart';
import 'widgets/no_tickets_placeholder.dart';
import 'widgets/ticket_card_widget.dart';
import 'widgets/welcome_card.dart';

class PaymentData {
  final String origin;
  final String destination;
  final int passengerCount;
  final int totalFare;
  final String? paymentMethodKey;
  final String? paymentMethodName;

  const PaymentData({
    required this.origin,
    required this.destination,
    required this.passengerCount,
    required this.totalFare,
    this.paymentMethodKey,
    this.paymentMethodName,
  });
}

/// 1:1 Pure Recreation of `#view-home` & Section A routing from Web Prototype/index.html
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  int _historyInitialTab = 0;
  UserProfileModel _userProfile = const UserProfileModel();

  List<TicketModel> _tickets = TicketModel.getInitialTickets();
  List<TicketModel> _history = TicketModel.getInitialHistory();

  // Active full screen overlays in Section A
  TicketModel? _activeDetailTicket;
  PaymentData? _activePaymentData;
  TicketModel? _activeQrTicket;

  // Active Auth views
  String? _activeAuthScreen; // 'phone', 'otp', 'setup'
  String? _authPendingPhone;

  @override
  void initState() {
    super.initState();
    _loadPersistedData();
  }

  Future<void> _loadPersistedData() async {
    final storage = await AppStorageService.getInstance();
    final profile = storage.loadUserProfile();
    final savedTickets = storage.loadTickets();
    final savedHistory = storage.loadHistory();

    if (mounted) {
      setState(() {
        if (profile != null) {
          _userProfile = profile;
        }
        if (savedTickets != null) {
          _tickets = savedTickets;
        }
        if (savedHistory != null) {
          _history = savedHistory;
        }
      });
    }

    _syncWithSupabase();
  }

  Future<void> _syncWithSupabase() async {
    try {
      final phone = _userProfile.phoneNumber;
      final serverProfile = await SupabaseService.instance.getOrCreatePassenger(phoneNumber: phone);
      final serverTickets = await SupabaseService.instance.fetchLiveTickets(phone);
      final serverHistory = await SupabaseService.instance.fetchTripHistory(phone);

      if (mounted) {
        setState(() {
          if (serverProfile != null) {
            _userProfile = serverProfile;
          }
          if (serverTickets.isNotEmpty) {
            _tickets = serverTickets;
          }
          if (serverHistory.isNotEmpty) {
            _history = serverHistory;
          }
        });
        _saveTicketsAndHistory();
        _saveProfile(_userProfile);
      }
    } catch (e) {
      debugPrint('[HomeScreen] Supabase sync background note: $e');
    }
  }

  Future<void> _saveTicketsAndHistory() async {
    final storage = await AppStorageService.getInstance();
    await storage.saveTickets(_tickets);
    await storage.saveHistory(_history);
  }

  Future<void> _saveProfile(UserProfileModel profile) async {
    final storage = await AppStorageService.getInstance();
    await storage.saveUserProfile(profile);
  }

  List<TicketModel> get _sortedTickets {
    final list = List<TicketModel>.from(_tickets);
    list.sort((a, b) {
      if (a.status == TicketStatus.riding && b.status != TicketStatus.riding) return -1;
      if (a.status != TicketStatus.riding && b.status == TicketStatus.riding) return 1;
      return 0;
    });
    return list;
  }

  void _showToast(String message, {bool isError = false}) {
    AppToast.show(context, message, isError: isError);
  }

  void _handleRefundTicket(TicketModel ticket) {
    final refundFee = (ticket.totalFare * 0.1).round();
    final returnAmount = ticket.totalFare - refundFee;

    final refunded = ticket.copyWith(
      status: TicketStatus.refunded,
      completeTime: DateTime.now(),
    );

    setState(() {
      _tickets.removeWhere((t) => t.id == ticket.id);
      _history.insert(0, refunded);
      _activeDetailTicket = null;
    });
    _saveTicketsAndHistory();

    // Async sync with Supabase
    SupabaseService.instance.requestRefund(
      ticketId: ticket.id,
      phoneNumber: _userProfile.phoneNumber,
    );

    _showToast('Refund complete! ৳$returnAmount returned to your wallet.');
  }

  void _handleBottomNavScan() {
    // 1. If currently riding, check if timer is still active
    final ridingTicket = _tickets.cast<TicketModel?>().firstWhere(
      (t) => t?.status == TicketStatus.riding,
      orElse: () => null,
    );
    // 1. If riding ticket exists -> go directly to QrDisplayScreen
    if (ridingTicket != null) {
      setState(() {
        _activeQrTicket = ridingTicket;
      });
      return;
    }

    // 2. Filter available tickets
    final availableTickets = _tickets.where((t) => t.status == TicketStatus.available).toList();

    if (availableTickets.isEmpty) {
      _showToast(
        'No active or available tickets to show. Please buy a ticket first.',
        isError: true,
      );
      return;
    }

    // 3. Exactly 1 available ticket -> start with loading
    if (availableTickets.length == 1) {
      LoadingSceneOverlay.runWithLoading(
        context,
        'Generating Ticket QR...',
        () {
          if (mounted) {
            setState(() {
              _activeQrTicket = availableTickets.first;
            });
          }
        },
      );
      return;
    }

    // 4. Multiple available tickets -> show selector dialog
    TicketSelectDialog.show(context, tickets: availableTickets).then((selected) {
      if (selected != null && mounted) {
        LoadingSceneOverlay.runWithLoading(
          context,
          'Generating Ticket QR...',
          () {
            if (mounted) {
              setState(() {
                _activeQrTicket = selected;
              });
            }
          },
        );
      }
    });
  }

  Widget _buildHomeTicketList() {
    final tickets = _sortedTickets;
    if (tickets.isEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          96 + MediaQuery.of(context).padding.bottom,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        children: const [
          NoTicketsPlaceholder(),
        ],
      );
    }

    final hasRidingTicket = tickets.any((t) => t.status == TicketStatus.riding);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        96 + MediaQuery.of(context).padding.bottom,
      ),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];

        TicketCardStatus cardStatus;
        if (ticket.status == TicketStatus.riding) {
          cardStatus = TicketCardStatus.riding;
        } else if (hasRidingTicket && ticket.status == TicketStatus.available) {
          cardStatus = TicketCardStatus.locked;
        } else {
          cardStatus = TicketCardStatus.available;
        }

        return TicketCardWidget(
          origin: ticket.origin,
          destination: ticket.destination,
          date: ticket.formattedShortDate,
          passengerCount: ticket.passengerCount,
          fare: ticket.totalFare,
          expiry: ticket.formattedShortExpiry,
          status: cardStatus,
          exitQrActive: ticket.exitQrActive,
          onTap: () {
            if (ticket.status == TicketStatus.riding) {
              setState(() {
                _activeQrTicket = ticket;
              });
            } else {
              setState(() {
                _activeDetailTicket = ticket;
              });
            }
          },
          onUseTicket: () {
            if (ticket.status == TicketStatus.riding) {
              setState(() {
                _activeQrTicket = ticket;
              });
            } else if (ticket.status == TicketStatus.available) {
              LoadingSceneOverlay.runWithLoading(
                context,
                'Generating Ticket QR...',
                () {
                  if (mounted) {
                    setState(() {
                      _activeQrTicket = ticket;
                    });
                  }
                },
              );
            }
          },
          onRefund: () {
            setState(() {
              _activeDetailTicket = ticket;
            });
          },
        );
      },
    );
  }

  Widget _buildCurrentNavView() {
    switch (_currentNavIndex) {
      case 1:
        return BuyTicketScreen(
          onBack: () => setState(() => _currentNavIndex = 0),
          onProceedToPaymentWithMethod: (origin, dest, count, fare, methodKey, methodName) {
            setState(() {
              _activePaymentData = PaymentData(
                origin: origin,
                destination: dest,
                passengerCount: count,
                totalFare: fare,
                paymentMethodKey: methodKey,
                paymentMethodName: methodName,
              );
            });
          },
          onProceedToPayment: (origin, dest, count, fare) {
            setState(() {
              _activePaymentData = PaymentData(
                origin: origin,
                destination: dest,
                passengerCount: count,
                totalFare: fare,
              );
            });
          },
        );
      case 2:
        return HistoryScreen(
          onBack: () => setState(() => _currentNavIndex = 0),
          historyTickets: _history.map((t) => HistoryTicketModel.fromTicketModel(t)).toList(),
          initialTabIndex: _historyInitialTab,
        );
      case 3:
        return ProfileScreen(
          initialProfile: _userProfile,
          onProfileSaved: (updated) {
            setState(() => _userProfile = updated);
            _saveProfile(updated);
          },
          onLogout: () async {
            final emptyProfile = const UserProfileModel(
              fullName: 'Commuter',
              phoneNumber: '',
              email: '',
              gender: '',
              dob: '',
              avatarUrl: null,
            );
            setState(() {
              _userProfile = emptyProfile;
              _currentNavIndex = 0;
              _activeAuthScreen = 'phone';
            });
            final storage = await AppStorageService.getInstance();
            await storage.saveUserProfile(emptyProfile);
            await storage.saveAuthState(isAuthenticated: false);
            _showToast('Logged out successfully!');
          },
          onOpenPhoneLogin: () {
            setState(() => _activeAuthScreen = 'phone');
          },
          onOpenOtpVerification: () {
            setState(() {
              _authPendingPhone = _userProfile.phoneNumber;
              _activeAuthScreen = 'otp';
            });
          },
          onOpenProfileSetup: () {
            setState(() => _activeAuthScreen = 'setup');
          },
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome Card (.welcome-card)
            WelcomeCard(
              greeting: _getGreeting(_userProfile.fullName.split(' ').first),
              subtitle: 'Ready for your ride?',
              avatarUrl: _userProfile.avatarUrl,
              onBuyTicket: () => setState(() => _currentNavIndex = 1),
              onProfileTap: () => setState(() => _currentNavIndex = 3),
            ),

            // 2. Section Header (.tickets-section__header)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                'My Tickets',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF181C1A),
                ),
              ),
            ),

            // 3. Tickets List
            Expanded(
              child: _buildHomeTicketList(),
            ),
          ],
        );
    }
  }

  bool _handleSystemPop() {
    if (_activeAuthScreen != null) {
      if (_activeAuthScreen == 'setup') {
        setState(() => _activeAuthScreen = 'otp');
      } else if (_activeAuthScreen == 'otp') {
        setState(() => _activeAuthScreen = 'phone');
      } else {
        setState(() => _activeAuthScreen = null);
      }
      return false;
    }

    if (_activeQrTicket != null) {
      setState(() => _activeQrTicket = null);
      return false;
    }

    if (_activePaymentData != null) {
      setState(() => _activePaymentData = null);
      return false;
    }

    if (_activeDetailTicket != null) {
      setState(() => _activeDetailTicket = null);
      return false;
    }

    if (_currentNavIndex != 0) {
      setState(() => _currentNavIndex = 0);
      return false;
    }

    return true; // Allow app exit on home view
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          final canExit = _handleSystemPop();
          if (canExit) {
            Navigator.of(context).maybePop();
          }
        }
      },
      child: _buildScreenContent(context),
    );
  }

  Widget _buildScreenContent(BuildContext context) {
    // Check if auth screens are active
    if (_activeAuthScreen == 'phone') {
      return PhoneLoginScreen(
        onNext: (fullPhone) {
          setState(() {
            _authPendingPhone = fullPhone;
            _activeAuthScreen = 'otp';
          });
          SupabaseService.instance.requestOtp(fullPhone);
        },
        onBack: () => setState(() => _activeAuthScreen = null),
      );
    }

    if (_activeAuthScreen == 'otp') {
      return OtpVerificationScreen(
        phone: _authPendingPhone ?? _userProfile.phoneNumber,
        onBack: () => setState(() => _activeAuthScreen = 'phone'),
        onVerified: () {
          setState(() {
            _activeAuthScreen = 'setup';
          });
        },
      );
    }

    if (_activeAuthScreen == 'setup') {
      return ProfileSetupScreen(
        onSkip: () async {
          final phone = _authPendingPhone ?? _userProfile.phoneNumber;
          final serverProfile = await SupabaseService.instance.getOrCreatePassenger(phoneNumber: phone);
          final updated = serverProfile ?? _userProfile.copyWith(phoneNumber: phone);
          setState(() {
            _userProfile = updated;
            _activeAuthScreen = null;
            _currentNavIndex = 0;
          });
          await _saveProfile(updated);
          final storage = await AppStorageService.getInstance();
          await storage.saveAuthState(isAuthenticated: true, phoneNumber: updated.phoneNumber);
          _showToast('Logged in successfully!');
          _syncWithSupabase();
        },
        onComplete: (fullName, avatar) async {
          final phone = _authPendingPhone ?? _userProfile.phoneNumber;
          final updated = _userProfile.copyWith(
            fullName: fullName.isNotEmpty ? fullName : _userProfile.fullName,
            avatarUrl: avatar,
            phoneNumber: phone,
          );
          setState(() {
            _userProfile = updated;
            _activeAuthScreen = null;
            _currentNavIndex = 0;
          });
          await _saveProfile(updated);
          final storage = await AppStorageService.getInstance();
          await storage.saveAuthState(isAuthenticated: true, phoneNumber: updated.phoneNumber);
          _showToast('Profile setup completed successfully!');
          
          await SupabaseService.instance.updatePassengerProfile(updated);
          _syncWithSupabase();
        },
      );
    }

    // Check if any full-screen overlay from Section A is active
    if (_activeDetailTicket != null) {
      final currentTicket = _tickets.firstWhere(
        (t) => t.id == _activeDetailTicket!.id,
        orElse: () => _activeDetailTicket!,
      );

      final hasRidingTicket = _tickets.any((t) => t.status == TicketStatus.riding);
      final isLocked = hasRidingTicket && currentTicket.status == TicketStatus.available;

      return TicketDetailsScreen(
        ticket: currentTicket,
        isLocked: isLocked,
        onBack: () => setState(() => _activeDetailTicket = null),
        onUseTicket: () {
          setState(() {
            _activeDetailTicket = null;
            _activeQrTicket = currentTicket;
          });
        },
        onShowQr: () {
          setState(() {
            _activeDetailTicket = null;
            _activeQrTicket = currentTicket;
          });
        },
        onRefundTicket: _handleRefundTicket,
      );
    }

    if (_activePaymentData != null) {
      return PaymentScreen(
        origin: _activePaymentData!.origin,
        destination: _activePaymentData!.destination,
        passengerCount: _activePaymentData!.passengerCount,
        totalFare: _activePaymentData!.totalFare,
        initialMethodKey: _activePaymentData!.paymentMethodKey,
        initialMethodName: _activePaymentData!.paymentMethodName,
        onBack: () => setState(() => _activePaymentData = null),
        onTicketPurchased: (purchasedTicket) async {
          setState(() {
            _tickets.add(purchasedTicket);
            _activePaymentData = null;
            _currentNavIndex = 0;
          });
          _saveTicketsAndHistory();
          _showToast('Ticket ${purchasedTicket.id} purchased successfully!');

          // Async sync with Supabase
          final serverTicket = await SupabaseService.instance.buyTicket(
            phoneNumber: _userProfile.phoneNumber,
            origin: purchasedTicket.origin,
            destination: purchasedTicket.destination,
            passengerCount: purchasedTicket.passengerCount,
            paymentMethod: purchasedTicket.paymentMethod,
          );

          if (serverTicket != null && mounted) {
            setState(() {
              final idx = _tickets.indexWhere((t) => t.id == purchasedTicket.id);
              if (idx != -1) {
                _tickets[idx] = serverTicket;
              }
            });
            _saveTicketsAndHistory();
          }
        },
      );
    }

    if (_activeQrTicket != null) {
      final currentTicket = _tickets.firstWhere(
        (t) => t.id == _activeQrTicket!.id,
        orElse: () => _activeQrTicket!,
      );

      return QrDisplayScreen(
        ticket: currentTicket,
        onBack: () => setState(() => _activeQrTicket = null),
        onPassEntryBarrier: () {
          final now = DateTime.now();
          final updatedTicket = currentTicket.copyWith(
            status: TicketStatus.riding,
            exitQrActive: false,
            qrExpiryTime: now.add(Duration(seconds: currentTicket.qrDurationSeconds)),
          );

          setState(() {
            final idx = _tickets.indexWhere((t) => t.id == updatedTicket.id);
            if (idx != -1) {
              _tickets[idx] = updatedTicket;
            }
            _activeQrTicket = updatedTicket;
          });
          _saveTicketsAndHistory();

          // Sync with Supabase
          SupabaseService.instance.passEntryBarrier(
            ticketId: currentTicket.id,
            phoneNumber: _userProfile.phoneNumber,
          );

          _showToast('Entry gate opened! Journey started.');
        },
        onRegenerateQr: () {
          final now = DateTime.now();
          final updatedTicket = currentTicket.copyWith(
            qrExpiryTime: now.add(Duration(seconds: currentTicket.qrDurationSeconds)),
            exitQrExpiryTime: currentTicket.exitQrActive
                ? now.add(Duration(seconds: currentTicket.qrDurationSeconds))
                : null,
          );

          setState(() {
            final idx = _tickets.indexWhere((t) => t.id == updatedTicket.id);
            if (idx != -1) {
              _tickets[idx] = updatedTicket;
            }
            _activeQrTicket = updatedTicket;
          });
          _saveTicketsAndHistory();
          _showToast('QR code regenerated successfully!');
        },
        onCompleteTrip: () {
          final completed = currentTicket.copyWith(
            status: TicketStatus.completed,
            completeTime: DateTime.now(),
            exitQrActive: false,
          );

          setState(() {
            _tickets.removeWhere((t) => t.id == currentTicket.id);
            _history.insert(0, completed);
            _activeQrTicket = null;
            _historyInitialTab = 0;
            _currentNavIndex = 2; // Jump to history tab
          });
          _saveTicketsAndHistory();

          // Sync with Supabase
          SupabaseService.instance.passExitBarrier(
            ticketId: currentTicket.id,
            phoneNumber: _userProfile.phoneNumber,
          );

          _showToast('Exit gate opened! Journey completed.');
        },
      );
    }

    // Default Main Scaffolding with Bottom Nav
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppGradients.pageGradient,
        ),
        child: Stack(
          children: [
            // 1. Screen View Content
            Positioned.fill(
              child: _buildCurrentNavView(),
            ),

            // 2. Bottom Navigation Bar (.bottom-nav-rounded)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavBar(
                currentIndex: _currentNavIndex,
                onTabSelected: (index) {
                  setState(() => _currentNavIndex = index);
                },
                onScanPressed: _handleBottomNavScan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting(String name) {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return 'Good Morning, $name';
    } else if (hour >= 12 && hour < 15) {
      return 'Good Noon, $name';
    } else if (hour >= 15 && hour < 18) {
      return 'Good Afternoon, $name';
    } else if (hour >= 18 && hour < 22) {
      return 'Good Evening, $name';
    } else {
      return 'Good Night, $name';
    }
  }
}
