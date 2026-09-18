import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../shared/app_gradients.dart';
import 'models/user_profile_model.dart';
import 'widgets/custom_date_picker_dialog.dart';
import 'widgets/gender_picker_dialog.dart';
import 'widgets/loading_scene_overlay.dart';
import 'widgets/photo_picker_bottom_sheet.dart';
import 'widgets/side_menu_drawer.dart';

/// 1:1 Strict Pure Flutter Recreation of `#view-profile` from Web Prototype/index.html
class ProfileScreen extends StatefulWidget {
  final UserProfileModel? initialProfile;
  final ValueChanged<UserProfileModel>? onProfileSaved;
  final VoidCallback? onLogout;
  final VoidCallback? onOpenPhoneLogin;
  final VoidCallback? onOpenOtpVerification;
  final VoidCallback? onOpenProfileSetup;

  const ProfileScreen({
    super.key,
    this.initialProfile,
    this.onProfileSaved,
    this.onLogout,
    this.onOpenPhoneLogin,
    this.onOpenOtpVerification,
    this.onOpenProfileSetup,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  late UserProfileModel _savedProfile;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late String _selectedGender;
  late String _selectedDob;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _savedProfile = widget.initialProfile ?? const UserProfileModel();
    _nameController = TextEditingController(text: _savedProfile.fullName);
    _emailController = TextEditingController(text: _savedProfile.email);
    _selectedGender = _savedProfile.gender;
    _selectedDob = _savedProfile.dob;
    _avatarUrl = _savedProfile.avatarUrl;

    _nameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    return _nameController.text.trim() != _savedProfile.fullName ||
        _emailController.text.trim() != _savedProfile.email ||
        _selectedGender != _savedProfile.gender ||
        _selectedDob != _savedProfile.dob ||
        _avatarUrl != _savedProfile.avatarUrl;
  }

  String get _genderDisplayText {
    switch (_selectedGender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'prefer_not_to_say':
        return 'Prefer not to say';
      default:
        return '';
    }
  }

  String get _dobDisplayText {
    if (_selectedDob.isEmpty) return '';
    try {
      final parts = _selectedDob.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${months[month - 1]} ${day.toString().padLeft(2, '0')}, $year';
      }
    } catch (_) {}
    return _selectedDob;
  }

  void _openSideMenu() {
    SideMenuDrawer.show(
      context,
      onLogout: widget.onLogout,
      onOpenPhoneLogin: widget.onOpenPhoneLogin,
      onOpenOtpVerification: widget.onOpenOtpVerification,
      onOpenProfileSetup: widget.onOpenProfileSetup,
      onShowToast: (msg) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (file != null && mounted) {
        final bytes = await file.readAsBytes();
        final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        LoadingSceneOverlay.runWithLoading(
          context,
          'Updating profile photo...',
          () {
            setState(() {
              _avatarUrl = base64String;
            });
            _showToast('Profile photo updated successfully');
          },
        );
      }
    } catch (e) {
      _showToast('Failed to select image: $e');
    }
  }

  void _openPhotoPicker() {
    PhotoPickerBottomSheet.show(
      context,
      onTakePhoto: () => _pickImage(ImageSource.camera),
      onChooseGallery: () => _pickImage(ImageSource.gallery),
      onRemovePhoto: () {
        setState(() {
          _avatarUrl = null;
        });
        _showToast('Profile photo removed');
      },
    );
  }

  Future<void> _openGenderPicker() async {
    final result = await GenderPickerDialog.show(
      context,
      currentGender: _selectedGender,
    );
    if (result != null) {
      setState(() => _selectedGender = result);
    }
  }

  Future<void> _openDatePicker() async {
    DateTime initial = DateTime(1990, 1, 1);
    if (_selectedDob.isNotEmpty) {
      try {
        final parts = _selectedDob.split('-');
        if (parts.length == 3) {
          initial = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (_) {}
    }

    final result = await CustomDatePickerDialog.show(
      context,
      initialDate: initial,
    );
    if (result != null) {
      final y = result.year;
      final m = result.month.toString().padLeft(2, '0');
      final d = result.day.toString().padLeft(2, '0');
      setState(() => _selectedDob = '$y-$m-$d');
    }
  }

  void _saveChanges() {
    if (!_isDirty) {
      _showToast('No changes made in profile.');
      return;
    }

    LoadingSceneOverlay.runWithLoading(
      context,
      'Saving profile...',
      () {
        final updatedProfile = _savedProfile.copyWith(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          gender: _selectedGender,
          dob: _selectedDob,
          avatarUrl: _avatarUrl,
          clearAvatar: _avatarUrl == null,
        );

        setState(() {
          _savedProfile = updatedProfile;
        });

        if (widget.onProfileSaved != null) {
          widget.onProfileSaved!(updatedProfile);
        }

        _showToast('Profile information saved successfully!');
      },
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          // 1. Top Header Row (.profile-header-row)
          Padding(
            padding: EdgeInsets.fromLTRB(16, topSafe + 8, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181C1A), // var(--color-on-surface)
                  ),
                ),
                IconButton(
                  onPressed: _openSideMenu,
                  icon: const Icon(Icons.menu, size: 24, color: Color(0xFF181C1A)),
                  tooltip: 'Open menu',
                  splashRadius: 22,
                ),
              ],
            ),
          ),

          // 2. Scrollable Body Container (.profile-scroll-container)
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 2, 16, 80 + bottomSafe),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                // 3. Avatar Section (.avatar-section)
                Center(
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Avatar Ring (.avatar-wrapper)
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                              colors: [Color(0xFF0B9175), Color(0xFF005140)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33005140),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE0E3E0), // var(--color-surface-highest)
                            ),
                            child: _buildAvatarCircleContent(),
                          ),
                        ),

                          // Camera Edit Button (.avatar-edit-btn)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _openPhotoPicker,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF005140), // var(--color-primary)
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFF7FAF6), // var(--color-surface)
                                    width: 2,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x33000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // User Display Name (.profile-name)
                      Text(
                        _savedProfile.fullName,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF181C1A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),

                      // User Phone (.profile-phone)
                      Text(
                        _savedProfile.phoneNumber,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          height: 1.2,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF3E4945),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 4. Form Fields (.profile-form & .form-grid)
                _buildFormField(
                  label: 'Full Name',
                  icon: Icons.person,
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF181C1A),
                    ),
                    decoration: _inputDecoration(
                      icon: Icons.person,
                      hint: 'Enter your full name',
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                _buildFormField(
                  label: 'Email Address',
                  icon: Icons.mail,
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF181C1A),
                    ),
                    decoration: _inputDecoration(
                      icon: Icons.mail,
                      hint: 'Enter your email address',
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                GestureDetector(
                  onTap: _openGenderPicker,
                  behavior: HitTestBehavior.opaque,
                  child: _buildFormField(
                    label: 'Gender',
                    icon: Icons.wc,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: TextEditingController(text: _genderDisplayText),
                        readOnly: true,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF181C1A),
                        ),
                        decoration: _inputDecoration(
                          icon: Icons.wc,
                          hint: 'Select Gender',
                          suffixIcon: Icons.arrow_drop_down,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                GestureDetector(
                  onTap: _openDatePicker,
                  behavior: HitTestBehavior.opaque,
                  child: _buildFormField(
                    label: 'Date of Birth',
                    icon: Icons.calendar_today,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: TextEditingController(text: _dobDisplayText),
                        readOnly: true,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF181C1A),
                        ),
                        decoration: _inputDecoration(
                          icon: Icons.calendar_today,
                          hint: 'Select Date of Birth',
                          suffixIcon: Icons.arrow_drop_down,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 5. Save Button (.btn-save)
                SizedBox(
                  height: 44,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isDirty
                          ? const Color(0xFF005140) // var(--color-primary)
                          : const Color(0xFFBEC9C3), // var(--color-outline-variant)
                      foregroundColor: _isDirty
                          ? Colors.white
                          : const Color(0xFF3E4945), // var(--color-on-surface-variant)
                      elevation: _isDirty ? 2 : 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            letterSpacing: 0.1,
                            fontWeight: FontWeight.w600,
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
    ),
  );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF181C1A), // var(--color-on-surface)
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({
    required IconData icon,
    required String hint,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFFFFFFF), // var(--color-surface-lowest)
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: Color(0xFF6E7A75),
      ),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF3E4945)),
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, size: 20, color: const Color(0xFF6E7A75))
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBEC9C3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBEC9C3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF005140), width: 1.5),
      ),
    );
  }

  Widget _buildAvatarCircleContent() {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      if (_avatarUrl!.startsWith('data:image') || !_avatarUrl!.startsWith('http')) {
        try {
          String cleanBase64 = _avatarUrl!;
          if (cleanBase64.contains(',')) {
            cleanBase64 = cleanBase64.split(',').last;
          }
          final bytes = base64Decode(cleanBase64);
          return ClipOval(
            child: Image.memory(
              bytes,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildFallbackAvatarIcon(),
            ),
          );
        } catch (_) {
          return _buildFallbackAvatarIcon();
        }
      } else {
        return ClipOval(
          child: Image.network(
            _avatarUrl!,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildFallbackAvatarIcon(),
          ),
        );
      }
    }
    return _buildFallbackAvatarIcon();
  }

  Widget _buildFallbackAvatarIcon() {
    return const Center(
      child: Icon(
        Icons.person,
        size: 46,
        color: Color(0xFF005140),
      ),
    );
  }
}
