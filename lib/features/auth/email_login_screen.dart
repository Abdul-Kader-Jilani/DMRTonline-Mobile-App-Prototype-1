import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../shared/app_gradients.dart';

/// Clean Native Email Login Screen with Real Supabase OTP for DMRT Online
class EmailLoginScreen extends StatefulWidget {
  final void Function(String email) onNext;
  final VoidCallback? onBack;

  const EmailLoginScreen({
    super.key,
    required this.onNext,
    this.onBack,
  });

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isBangla = false;
  bool _canProceed = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _controller.removeListener(_validateEmail);
    _controller.dispose();
    super.dispose();
  }

  void _validateEmail() {
    final text = _controller.text.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    final valid = emailRegex.hasMatch(text);
    if (_canProceed != valid || _errorMessage != null) {
      setState(() {
        _canProceed = valid;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_canProceed || _isLoading) return;
    final email = _controller.text.trim().toLowerCase();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await SupabaseService.instance.sendEmailOtp(email);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (res['success'] == true) {
          widget.onNext(email);
        } else {
          setState(() {
            _errorMessage = res['message'] as String? ?? 'Failed to send verification code. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred: $e';
        });
      }
    }
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
                  _isBangla ? 'আপনার ইমেল ঠিকানা লিখুন' : 'Enter your email address',
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
                  _isBangla
                      ? 'আমরা আপনার ইনবক্সে একটি ৬-সংখ্যার ওটিপি কোড পাঠাব'
                      : "We'll send a 6-digit OTP code to your inbox",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF3E4945),
                  ),
                ),
                const SizedBox(height: 28),

                // Email Input Container
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _errorMessage != null ? const Color(0xFFBA1A1A) : const Color(0xFFBEC9C3),
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
                      // Mail Icon prefix
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
                          child: Icon(
                            Icons.mail_outline,
                            size: 20,
                            color: Color(0xFF005140),
                          ),
                        ),
                      ),
                      // Text Field
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textCapitalization: TextCapitalization.none,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF181C1A),
                          ),
                          decoration: InputDecoration(
                            hintText: _isBangla ? 'user@example.com' : 'user@example.com',
                            hintStyle: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF6E7A75),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: (_) => _handleSubmit(),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFFBA1A1A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Submit Button (.btn-next)
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_canProceed && !_isLoading) ? _handleSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canProceed ? const Color(0xFF005140) : const Color(0xFFEBEFEB),
                      foregroundColor: _canProceed ? Colors.white : const Color(0xFF6E7A75),
                      elevation: _canProceed ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isBangla ? 'যাচাইকরণ কোড পাঠান' : 'Send Code',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _canProceed ? Colors.white : const Color(0xFF6E7A75),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Terms Notice
                Center(
                  child: Text(
                    _isBangla
                        ? 'পরবর্তী ধাপে যাওয়ার মাধ্যমে আপনি ঢাকা ম্যাস ট্রানজিট নীতিমালায় সম্মতি দিচ্ছেন'
                        : 'By proceeding, you agree to Dhaka Mass Rapid Transit Terms & Privacy',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6E7A75),
                    ),
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
