import 'package:flutter/material.dart';
import 'loading_scene_overlay.dart';
import 'logout_confirm_dialog.dart';
import 'side_menu_dialogs.dart';

/// 1:1 Strict Pure Flutter Recreation of `#side-menu-overlay` & `.side-menu-drawer`
class SideMenuDrawer extends StatefulWidget {
  final VoidCallback? onLogout;
  final Function(String message)? onShowToast;
  final VoidCallback? onOpenPhoneLogin;
  final VoidCallback? onOpenOtpVerification;
  final VoidCallback? onOpenProfileSetup;

  const SideMenuDrawer({
    super.key,
    this.onLogout,
    this.onShowToast,
    this.onOpenPhoneLogin,
    this.onOpenOtpVerification,
    this.onOpenProfileSetup,
  });

  static void show(
    BuildContext context, {
    VoidCallback? onLogout,
    Function(String message)? onShowToast,
    VoidCallback? onOpenPhoneLogin,
    VoidCallback? onOpenOtpVerification,
    VoidCallback? onOpenProfileSetup,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SideMenu',
      barrierColor: const Color(0x73000000), // rgba(0,0,0,0.45)
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => Align(
        alignment: Alignment.centerRight,
        child: SideMenuDrawer(
          onLogout: () async {
            Navigator.of(ctx).pop();
            final confirmed = await LogoutConfirmDialog.show(context);
            if (confirmed == true && onLogout != null) {
              onLogout();
            }
          },
          onShowToast: onShowToast,
          onOpenPhoneLogin: () {
            Navigator.of(ctx).pop();
            if (onOpenPhoneLogin != null) onOpenPhoneLogin();
          },
          onOpenOtpVerification: () {
            Navigator.of(ctx).pop();
            if (onOpenOtpVerification != null) onOpenOtpVerification();
          },
          onOpenProfileSetup: () {
            Navigator.of(ctx).pop();
            if (onOpenProfileSetup != null) onOpenProfileSetup();
          },
        ),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curvedValue = Curves.easeOutCubic.transform(anim1.value);
        return Transform.translate(
          offset: Offset((1.0 - curvedValue) * 300, 0),
          child: child,
        );
      },
    );
  }

  @override
  State<SideMenuDrawer> createState() => _SideMenuDrawerState();
}

class _SideMenuDrawerState extends State<SideMenuDrawer> {
  bool _isBangla = false;

  void _toast(String msg) {
    if (widget.onShowToast != null) {
      widget.onShowToast!(msg);
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.75).clamp(260.0, 320.0);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: drawerWidth,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF), // var(--color-surface-lowest)
          boxShadow: [
            BoxShadow(
              color: Color(0x26000000), // -4px 0 24px rgba(0,0,0,0.15)
              blurRadius: 24,
              offset: Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header (.side-menu-header)
            Padding(
              padding: EdgeInsets.fromLTRB(16, topSafe + 16, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isBangla ? 'মেনু' : 'Menu',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF005140), // var(--color-primary)
                    ),
                  ),

                  // Language Toggle (.lang-toggle)
                  GestureDetector(
                    onTap: () {
                      setState(() => _isBangla = !_isBangla);
                      _toast(_isBangla ? 'ভাষা পরিবর্তন করা হয়েছে: বাংলা' : 'Language changed to: English');
                    },
                    child: Container(
                      width: 76,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBEFEB), // var(--color-surface-container)
                        borderRadius: BorderRadius.circular(9999),
                        border: Border.all(
                          color: const Color(0xFF005140),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Stack(
                        children: [
                          // Sliding pill
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
                          // Labels
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
            ),

            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E3E0)),

            // 2. Menu Items List (.side-menu-content)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildMenuItem(
                    icon: Icons.check_circle_outline,
                    label: _isBangla ? "করণীয় (Do's)" : "Do's",
                    onTap: () {
                      Navigator.of(context).pop();
                      DosGuidelinesDialog.show(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.cancel_outlined,
                    label: _isBangla ? "বর্জনীয় (Don'ts)" : "Don'ts",
                    onTap: () {
                      Navigator.of(context).pop();
                      DontsGuidelinesDialog.show(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.map_outlined,
                    label: _isBangla ? "মেট্রো ম্যাপ" : "Map",
                    onTap: () {
                      Navigator.of(context).pop();
                      MetroMapDialog.show(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    label: _isBangla ? "অনুমতিসমূহ" : "Permissions",
                    onTap: () {
                      Navigator.of(context).pop();
                      PermissionsDialog.show(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.contact_support_outlined,
                    label: _isBangla ? "সহায়তা কেন্দ্র" : "Support Request",
                    onTap: () {
                      Navigator.of(context).pop();
                      SupportRequestDialog.show(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.policy_outlined,
                    label: _isBangla ? "নীতিমালা ও শর্তাবলী" : "Policies",
                    onTap: () {
                      Navigator.of(context).pop();
                      PoliciesDialog.show(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.sync,
                    label: _isBangla ? "লোডিং দৃশ্য" : "Loading Scene",
                    onTap: () {
                      Navigator.of(context).pop();
                      LoadingSceneOverlay.show(context);
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.smartphone_outlined,
                    label: _isBangla ? "ফোন লগইন পৃষ্ঠা" : "Phone Login Page",
                    onTap: () {
                      if (widget.onOpenPhoneLogin != null) {
                        widget.onOpenPhoneLogin!();
                      }
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.pin_outlined,
                    label: _isBangla ? "ওটিপি যাচাই পৃষ্ঠা" : "OTP Verification Page",
                    onTap: () {
                      if (widget.onOpenOtpVerification != null) {
                        widget.onOpenOtpVerification!();
                      }
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.manage_accounts_outlined,
                    label: _isBangla ? "প্রোফাইল সেটআপ" : "Profile Setup Page",
                    onTap: () {
                      if (widget.onOpenProfileSetup != null) {
                        widget.onOpenProfileSetup!();
                      }
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.logout,
                    label: _isBangla ? "লগআউট" : "Logout",
                    iconColor: const Color(0xFFBA1A1A),
                    labelColor: const Color(0xFFBA1A1A),
                    onTap: () {
                      if (widget.onLogout != null) widget.onLogout!();
                    },
                  ),
                ],
              ),
            ),

            // 3. Footer (.side-menu-version)
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomSafe),
              child: const Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF3E4945),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: iconColor ?? const Color(0xFF181C1A),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? const Color(0xFF181C1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
