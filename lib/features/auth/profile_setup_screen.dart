import 'package:flutter/material.dart';
import '../../shared/app_gradients.dart';
import '../profile/widgets/photo_picker_bottom_sheet.dart';

/// 1:1 Pure Recreation of `#view-auth-profile-setup` from Web Prototype/index.html
class ProfileSetupScreen extends StatefulWidget {
  final void Function(String fullName, String? avatar) onComplete;
  final VoidCallback onSkip;

  const ProfileSetupScreen({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _avatar;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handlePhotoPick() {
    PhotoPickerBottomSheet.show(
      context,
      onTakePhoto: () {
        setState(() {
          _avatar = 'custom_photo';
        });
      },
      onChooseGallery: () {
        setState(() {
          _avatar = 'custom_photo';
        });
      },
      onRemovePhoto: () {
        setState(() {
          _avatar = null;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _nameController.text.trim().isNotEmpty || _avatar != null;

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
              // Top Bar with Skip Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onSkip,
                  icon: const Text(
                    'Skip',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF005140),
                    ),
                  ),
                  label: const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Color(0xFF005140),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                'Set up your profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF181C1A),
                ),
              ),
              const SizedBox(height: 32),

              // Avatar with camera badge (.setup-avatar-section)
              Center(
                child: GestureDetector(
                  onTap: _handlePhotoPick,
                  child: Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEBEFEB),
                          border: Border.all(
                            color: const Color(0xFF005140),
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _avatar != null ? Icons.face : Icons.person,
                            size: 52,
                            color: const Color(0xFF005140),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF005140),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_camera,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Full Name Text Input
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFBEC9C3),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181C1A),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your full name',
                    hintStyle: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: Color(0xFF6E7A75),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),

              // Get Started Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: canProceed
                      ? () => widget.onComplete(_nameController.text.trim(), _avatar)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canProceed ? const Color(0xFF005140) : const Color(0xFFBEC9C3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.rocket_launch, size: 18),
                    ],
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
