import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/supabase_service.dart';
import '../../shared/app_gradients.dart';

/// 1:1 Pure Recreation of `#view-auth-otp` from Web Prototype/index.html
class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final VoidCallback onBack;
  final VoidCallback onVerified;

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.onBack,
    required this.onVerified,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendSeconds = 60;
  Timer? _resendTimer;
  String _errorText = '';
  bool _isVerified = false;
  int _successWaveIndex = -1;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    for (int i = 0; i < 6; i++) {
      final index = i;
      _focusNodes[index].onKeyEvent = (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (_controllers[index].text.isEmpty && index > 0) {
            _controllers[index - 1].clear();
            _focusNodes[index - 1].requestFocus();
            if (_errorText.isNotEmpty) {
              setState(() => _errorText = '');
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      };
    }
    // Focus first input automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendSeconds = 60;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _onDigitChanged(int index, String value) {
    if (_errorText.isNotEmpty) {
      setState(() {
        _errorText = '';
      });
    }

    final cleanDigits = value.replaceAll(RegExp(r'\D'), '');

    // Multi-digit paste or multiple characters entered
    if (cleanDigits.length > 1) {
      // If user typed into an already populated box, take the newest character
      if (value.length > 1 && cleanDigits.length == 2) {
        final lastChar = cleanDigits.substring(cleanDigits.length - 1);
        _controllers[index].text = lastChar;
        _controllers[index].selection = const TextSelection.collapsed(offset: 1);
        if (index < 5) {
          _focusNodes[index + 1].requestFocus();
        } else {
          _verifyCode();
        }
        return;
      }

      // Pasted code
      for (int i = 0; i < cleanDigits.length && (index + i) < 6; i++) {
        _controllers[index + i].text = cleanDigits[i];
      }
      final targetIdx = (index + cleanDigits.length).clamp(0, 5);
      _focusNodes[targetIdx].requestFocus();
      if (_controllers.every((c) => c.text.isNotEmpty)) {
        _verifyCode();
      }
      return;
    }

    if (cleanDigits.isNotEmpty) {
      _controllers[index].text = cleanDigits;
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _verifyCode();
      }
    } else {
      _controllers[index].text = '';
    }
  }

  Future<void> _verifyCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) return;

    bool isValid = code == '000000';
    if (!isValid) {
      final res = await SupabaseService.instance.verifyOtp(
        phoneNumber: widget.phone,
        otp: code,
      );
      isValid = res != null && res['verified'] == true;
    }

    if (isValid) {
      setState(() {
        _errorText = '';
        _isVerified = true;
      });

      // Sequential wave outline color change animation
      for (int i = 0; i < 6; i++) {
        Future.delayed(Duration(milliseconds: i * 75), () {
          if (mounted) {
            setState(() {
              _successWaveIndex = i;
            });
          }
        });
      }

      Future.delayed(const Duration(milliseconds: 1100), () {
        if (mounted) {
          widget.onVerified();
        }
      });
    } else {
      setState(() {
        _isVerified = false;
        _errorText = 'Invalid OTP code. Use 000000 for testing.';
      });
      // Keep cursor active on the last box so backspacing works immediately
      _focusNodes[5].requestFocus();
      _controllers[5].selection = const TextSelection.collapsed(offset: 1);
    }
  }

  void _handleResend() {
    if (_resendSeconds > 0) return;
    for (var c in _controllers) {
      c.clear();
    }
    setState(() {
      _errorText = '';
      _isVerified = false;
      _successWaveIndex = -1;
    });
    _startResendTimer();
    SupabaseService.instance.requestOtp(widget.phone);
    _focusNodes[0].requestFocus();
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF005140)),
                  onPressed: widget.onBack,
                ),
              ),
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
              const Text(
                'Verify your number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF181C1A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the 6-digit code sent to ${widget.phone}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF3E4945),
                ),
              ),
              const SizedBox(height: 28),

              // 6-digit OTP Box Inputs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (idx) {
                  final isSuccess = _isVerified && idx <= _successWaveIndex;
                  final isError = _errorText.isNotEmpty;

                  return Container(
                    width: 44,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSuccess
                            ? const Color(0xFF005140)
                            : (isError
                                ? const Color(0xFFBA1A1A)
                                : (_focusNodes[idx].hasFocus
                                    ? const Color(0xFF005140)
                                    : const Color(0xFFBEC9C3))),
                        width: isSuccess || _focusNodes[idx].hasFocus ? 2.0 : 1.5,
                      ),
                      boxShadow: [
                        if (isSuccess)
                          const BoxShadow(
                            color: Color(0x33005140),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: TextField(
                        controller: _controllers[idx],
                        focusNode: _focusNodes[idx],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onTap: () {
                          // Select existing text on tap for easy replacement
                          _controllers[idx].selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _controllers[idx].text.length,
                          );
                        },
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF181C1A),
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) => _onDigitChanged(idx, val),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),

              // Feedback message
              if (_errorText.isNotEmpty)
                Text(
                  _errorText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFBA1A1A),
                  ),
                )
              else if (_isVerified)
                const Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Icon(Icons.check_circle, size: 18, color: Color(0xFF005140)),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF005140),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Resend code timer row (Wrap avoids overflow on tight widths/test environments)
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code? ",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF6E7A75),
                    ),
                  ),
                  GestureDetector(
                    onTap: _resendSeconds == 0 ? _handleResend : null,
                    child: Text(
                      _resendSeconds > 0
                          ? 'Resend ($_resendSeconds s)'
                          : 'Resend',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _resendSeconds == 0
                            ? const Color(0xFF005140)
                            : const Color(0xFF6E7A75),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
