import 'package:flutter/material.dart';

/// 1:1 Strict Pure Flutter Recreation of `#custom-gender-overlay`
class GenderPickerDialog extends StatelessWidget {
  final String selectedGender;
  final ValueChanged<String> onSelect;
  final VoidCallback onCancel;

  const GenderPickerDialog({
    super.key,
    required this.selectedGender,
    required this.onSelect,
    required this.onCancel,
  });

  static Future<String?> show(BuildContext context, {required String currentGender}) {
    return showDialog<String>(
      context: context,
      barrierColor: const Color(0x66000000),
      builder: (ctx) => GenderPickerDialog(
        selectedGender: currentGender,
        onSelect: (gender) => Navigator.of(ctx).pop(gender),
        onCancel: () => Navigator.of(ctx).pop(null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF), // var(--color-surface-lowest)
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title (.confirm-title)
              const Text(
                'Select Gender',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF005140), // var(--color-primary)
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Gender Options (.gender-picker-item)
              _buildGenderItem('male', 'Male'),
              const SizedBox(height: 8),
              _buildGenderItem('female', 'Female'),
              const SizedBox(height: 8),
              _buildGenderItem('prefer_not_to_say', 'Prefer not to say'),
              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFBA1A1A), // var(--color-error)
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderItem(String value, String label) {
    final isSelected = selectedGender.toLowerCase() == value.toLowerCase();

    return GestureDetector(
      onTap: () => onSelect(value),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF0B9175), Color(0xFF005140)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFFF1F4F0), // var(--color-surface-low)
          borderRadius: BorderRadius.circular(9999),
          border: isSelected
              ? null
              : Border.all(
                  color: const Color(0xFFE0E3E0),
                  width: 1,
                ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x33005140),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF181C1A),
                ),
                textAlign: TextAlign.center,
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
