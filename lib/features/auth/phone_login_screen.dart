import 'package:flutter/material.dart';
import '../../shared/app_gradients.dart';

/// 1:1 Pure Recreation of `#view-auth-phone` from Web Prototype/index.html
class PhoneLoginScreen extends StatefulWidget {
  final void Function(String fullPhone) onNext;
  final VoidCallback? onBack;

  const PhoneLoginScreen({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isBangla = false;
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_formatPhone);
  }

  @override
  void dispose() {
    _controller.removeListener(_formatPhone);
    _controller.dispose();
    super.dispose();
  }

  void _formatPhone() {
    String digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) {
      digits = digits.substring(0, 11);
    }

    String formatted = '';
    if (digits.length > 5) {
      formatted = '${digits.substring(0, 5)}-${digits.substring(5)}';
    } else {
      formatted = digits;
    }

    if (_controller.text != formatted) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    setState(() {
      _canProceed = digits.length == 11;
    });
  }

  void _handleSubmit() {
    if (!_canProceed) return;
    final fullPhone = '+880 ${_controller.text.trim()}';
    widget.onNext(fullPhone);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppGradients.authGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomSafe),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar: Optional Back + Language Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF005140)),
                      onPressed: widget.onBack,
                    )
                  else
                    const SizedBox(width: 48),

                  // Language Toggle (.lang-toggle)
                  GestureDetector(
                    onTap: () => setState(() => _isBangla = !_isBangla),
                    child: Container(
                      width: 76,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBEFEB),
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: const Color(0xFF005140),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Stack(
                        children: [
                          AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: _isBangla ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              width: 34,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF005140),
                                borderRadius: BorderRadius.circular(9999),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x26000000),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'EN',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: !_isBangla ? Colors.white : const Color(0xFF3E4945),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'বাং',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: _isBangla ? Colors.white : const Color(0xFF3E4945),
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
                ],
              ),
              const SizedBox(height: 12),

              // DMRT Brand Logo (.auth-logo-section & .auth-logo-img)
              Center(
                child: Image.asset(
                  'assets/dmrt/logo.png',
                  height: 190,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.directions_subway,
                    size: 80,
                    color: Color(0xFF005140),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header Titles
              Text(
                _isBangla ? 'আপনার ফোন নম্বর লিখুন' : 'Enter your phone number',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF181C1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isBangla ? 'আমরা আপনাকে একটি যাচাইকরণ কোড পাঠাব' : "We'll send you a verification code",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3E4945),
                ),
              ),
              const SizedBox(height: 28),

              // Phone Number Input Container (.auth-phone-wrapper)
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFBEC9C3),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Prefix +880
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Color(0xFFE0E3E0),
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          '+880',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF005140),
                          ),
                        ),
                      ),
                    ),

                    // Text Input
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF181C1A),
                          letterSpacing: 0.5,
                        ),
                        decoration: const InputDecoration(
                          hintText: '01XXX-XXXXXX',
                          hintStyle: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6E7A75),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),

                    // Clear button
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF6E7A75)),
                        onPressed: () {
                          _controller.clear();
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Next Action Button (.auth-btn)
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _canProceed ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canProceed ? const Color(0xFF005140) : const Color(0xFFBEC9C3),
                    foregroundColor: Colors.white,
                    elevation: _canProceed ? 4 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isBangla ? 'পরবর্তী' : 'Next',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Terms & Conditions Footer (.auth-terms)
              Text(
                _isBangla
                    ? 'এগিয়ে যাওয়ার মাধ্যমে, আপনি আমাদের সেবার শর্তাবলীতে সম্মত হচ্ছেন'
                    : 'By continuing, you agree to our Terms of Service & Privacy Policy',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF6E7A75),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
