import 'package:flutter/material.dart';
import '../../shared/app_gradients.dart';
import '../payment/widgets/payment_method_sheet.dart';
import 'models/station_data.dart';
import 'widgets/station_picker_bottom_sheet.dart';

/// 1:1 Strict Recreation of `#view-buy` from Web Prototype/index.html
class BuyTicketScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final void Function(String origin, String destination, int count, int totalFare)? onProceedToPayment;
  final void Function(
    String origin,
    String destination,
    int count,
    int totalFare,
    String methodKey,
    String methodName,
  )? onProceedToPaymentWithMethod;

  const BuyTicketScreen({
    super.key,
    this.onBack,
    this.onProceedToPayment,
    this.onProceedToPaymentWithMethod,
  });

  @override
  State<BuyTicketScreen> createState() => _BuyTicketScreenState();
}

class _BuyTicketScreenState extends State<BuyTicketScreen> {
  String? _origin;
  String? _destination;
  int _passengerCount = 1;
  double _swapTurns = 0.0;

  int get _singleFare => StationData.calculateFare(_origin, _destination);
  int get _totalFare => _singleFare * _passengerCount;
  bool get _isRouteComplete => _origin != null && _destination != null && _origin != _destination;

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? const Color(0xFFBA1A1A) : const Color(0xFF181C1A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _openStationPicker(StationPickerType type) async {
    final result = await StationPickerBottomSheet.show(
      context,
      pickerType: type,
      currentOrigin: _origin,
      currentDestination: _destination,
    );

    if (result != null) {
      setState(() {
        _origin = result.origin;
        _destination = result.destination;
      });
    }
  }

  void _swapStations() {
    if (_origin == null && _destination == null) return;
    setState(() {
      _swapTurns += 1.0;
      final temp = _origin;
      _origin = _destination;
      _destination = temp;
    });
  }

  void _adjustQuantity(int delta) {
    final newCount = _passengerCount + delta;
    if (newCount >= 1 && newCount <= 5) {
      setState(() {
        _passengerCount = newCount;
      });
    } else if (newCount > 5) {
      _showToast('Maximum of 5 tickets allowed per transaction.', isError: true);
    }
  }

  void _handleProceedToPayment() async {
    if (_origin == null || _destination == null) {
      _showToast('Please select both Origin and Destination stations.', isError: true);
      return;
    }
    if (_origin == _destination) {
      _showToast('Origin and Destination cannot be the same station.', isError: true);
      return;
    }

    // Open Payment Method Picker sheet (matches Web Prototype purchaseGroupTicket -> openPaymentMethodPicker)
    final chosen = await PaymentMethodSheet.show(context, selectedKey: 'mfs');
    if (chosen != null && mounted) {
      final methodTitle = chosen.key == 'mfs'
          ? 'Mobile Finance (bKash/Nagad)'
          : (chosen.key == 'card' ? 'Debit / Credit Card' : 'Internet Banking');

      if (widget.onProceedToPaymentWithMethod != null) {
        widget.onProceedToPaymentWithMethod!(
          _origin!,
          _destination!,
          _passengerCount,
          _totalFare,
          chosen.key,
          methodTitle,
        );
      } else if (widget.onProceedToPayment != null) {
        widget.onProceedToPayment!(
          _origin!,
          _destination!,
          _passengerCount,
          _totalFare,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppGradients.pageGradient,
        ),
        child: Column(
        children: [
          // 1. Fixed Fare Header (.fare-header-wrapper & .fare-header)
          Container(
            padding: EdgeInsets.fromLTRB(16, topSafe + 14, 16, 12),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // .fare-header__label
                const Text(
                  'TOTAL FARE',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181C1A), // var(--color-on-surface)
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 6),

                // .fare-header__amount
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '৳',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 44,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF005140), // var(--color-primary)
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isRouteComplete ? '$_totalFare' : '0',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF005140), // var(--color-primary)
                        height: 1.0,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Scrollable Section Container (.buy-scroll-container)
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 88 + bottomSafe),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                // 2.1 Fare Rate Bar (.fare-rate-bar)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005140), // var(--color-primary)
                    borderRadius: BorderRadius.circular(16), // var(--radius-xl)
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F005140),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          'Fare Rate (per ticket)',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRouteComplete ? '৳ $_singleFare' : '৳ --',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2.2 Route Selection Card (.route-card)
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18), // var(--radius-lg)
                    border: Border.all(
                      color: const Color(0x73BEC9C3), // rgba(190, 201, 195, 0.45)
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F003328),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // .route-card__title
                      const Text(
                        'Select Route',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Route List with Floating Swap Button
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerRight,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Icon Column: Origin Icon, Connector Line, Destination Icon
                              SizedBox(
                                width: 28,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 2),
                                    Icon(
                                      Icons.radio_button_checked,
                                      size: 24,
                                      color: _origin != null
                                          ? const Color(0xFF006B56) // var(--color-primary-container)
                                          : const Color(0xFF6E7A75), // var(--color-outline)
                                    ),
                                    Container(
                                      width: 3,
                                      height: 28,
                                      margin: const EdgeInsets.symmetric(vertical: 3),
                                      color: _isRouteComplete
                                          ? const Color(0xFF555555) // .station-item__connector--active
                                          : const Color(0xFFD6E4E1),
                                    ),
                                    Icon(
                                      Icons.location_on,
                                      size: 24,
                                      color: _destination != null
                                          ? const Color(0xFFD13014) // var(--color-destination)
                                          : const Color(0xFF6E7A75), // var(--color-outline)
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 2. Station Text Items Column
                              Expanded(
                                child: Column(
                                  children: [
                                    // Origin Text Row
                                    InkWell(
                                      onTap: () => _openStationPicker(StationPickerType.origin),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.only(top: 2, bottom: 10, right: 48),
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: Color(0xFFE0E3E0), // var(--color-surface-highest)
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            const Text(
                                              'FROM',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11,
                                                height: 1.3,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.6,
                                                color: Color(0xFF006B56),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _origin ?? 'Select Origin',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 16,
                                                fontWeight: _origin != null
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: _origin != null
                                                    ? Colors.black
                                                    : const Color(0xFF6E7A75),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    // Destination Text Row
                                    InkWell(
                                      onTap: () => _openStationPicker(StationPickerType.destination),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.only(top: 4, bottom: 6, right: 48),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            const Text(
                                              'TO',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11,
                                                height: 1.3,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.6,
                                                color: Color(0xFFD13014),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _destination ?? 'Select Destination',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 16,
                                                fontWeight: _destination != null
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                                color: _destination != null
                                                    ? Colors.black
                                                    : const Color(0xFF6E7A75),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Floating Swap Button (.route-swap-btn)
                          Positioned(
                            right: 0,
                            top: 24,
                            child: AnimatedRotation(
                              turns: _swapTurns,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _swapStations,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFBEC9C3), // var(--color-outline-variant)
                                        width: 1.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x14000000),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_upward,
                                          size: 15,
                                          color: Color(0xFF006B56),
                                        ),
                                        Icon(
                                          Icons.arrow_downward,
                                          size: 15,
                                          color: Color(0xFFD13014),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 2.3 Ticket Quantity Card (.quantity-card)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20), // var(--radius-2xl)
                    border: Border.all(
                      color: const Color(0xFFE6E9E5), // var(--color-surface-high)
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F003328),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // .quantity-row Labels
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Number of Tickets',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF181C1A), // var(--color-on-surface)
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Max 5 tickets per transaction',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF3E4945), // var(--color-on-surface-variant)
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // .quantity-stepper Stepper Buttons
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F4F0), // var(--color-surface-low)
                          borderRadius: BorderRadius.circular(9999), // var(--radius-full)
                          border: Border.all(
                            color: const Color(0xFFE6E9E5), // var(--color-surface-high)
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // .quantity-btn--minus
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _passengerCount > 1 ? () => _adjustQuantity(-1) : null,
                                borderRadius: BorderRadius.circular(9999),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _passengerCount > 1
                                        ? const Color(0xFF005140) // var(--color-primary)
                                        : const Color(0xFFBEC9C3), // var(--color-outline-variant)
                                    shape: BoxShape.circle,
                                    boxShadow: _passengerCount > 1
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x26000000),
                                              blurRadius: 8,
                                              offset: Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: const Icon(
                                    Icons.remove,
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            // .quantity-count
                            SizedBox(
                              width: 32,
                              child: Center(
                                child: Text(
                                  '$_passengerCount',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF181C1A),
                                  ),
                                ),
                              ),
                            ),

                            // .quantity-btn--plus
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _adjustQuantity(1),
                                borderRadius: BorderRadius.circular(9999),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _passengerCount < 5
                                        ? const Color(0xFF005140) // var(--color-primary)
                                        : const Color(0xFFBEC9C3),
                                    shape: BoxShape.circle,
                                    boxShadow: _passengerCount < 5
                                        ? const [
                                            BoxShadow(
                                              color: Color(0x26000000),
                                              blurRadius: 8,
                                              offset: Offset(0, 3),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2.4 Payment Action (.payment-section & .btn-pay)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleProceedToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRouteComplete
                            ? const Color(0xFF005140) // var(--color-primary)
                            : const Color(0xFFBEC9C3), // .btn-pay--inactive
                        foregroundColor: _isRouteComplete
                            ? Colors.white
                            : const Color(0xFF3E4945),
                        elevation: _isRouteComplete ? 4 : 0,
                        shadowColor: const Color(0x33005140),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999), // var(--radius-full)
                        ),
                      ),
                      child: const Text(
                        'Proceed to Payment',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}
