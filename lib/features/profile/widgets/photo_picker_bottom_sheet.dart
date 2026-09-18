import 'package:flutter/material.dart';

/// 1:1 Strict Pure Flutter Recreation of `.photo-picker-sheet`
class PhotoPickerBottomSheet extends StatelessWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseGallery;
  final VoidCallback onRemovePhoto;
  final VoidCallback onCancel;

  const PhotoPickerBottomSheet({
    super.key,
    required this.onTakePhoto,
    required this.onChooseGallery,
    required this.onRemovePhoto,
    required this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onTakePhoto,
    required VoidCallback onChooseGallery,
    required VoidCallback onRemovePhoto,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => PhotoPickerBottomSheet(
        onTakePhoto: () {
          Navigator.of(ctx).pop();
          onTakePhoto();
        },
        onChooseGallery: () {
          Navigator.of(ctx).pop();
          onChooseGallery();
        },
        onRemovePhoto: () {
          Navigator.of(ctx).pop();
          onRemovePhoto();
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEBEFEB), // var(--color-surface-container)
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomSafe),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle Bar (.photo-picker-handle)
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF6E7A75), // var(--color-outline)
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title (.photo-picker-title)
          const Text(
            'Update Profile Photo',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF181C1A), // var(--color-on-surface)
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Options Row (.photo-picker-options)
          Row(
            children: [
              // 1. Take Photo
              Expanded(
                child: _buildOptionCard(
                  icon: Icons.photo_camera,
                  label: 'Take Photo',
                  onTap: onTakePhoto,
                ),
              ),
              const SizedBox(width: 16),

              // 2. Choose from Gallery
              Expanded(
                child: _buildOptionCard(
                  icon: Icons.photo_library,
                  label: 'Choose from Gallery',
                  onTap: onChooseGallery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Actions Row (.photo-picker-actions)
          Row(
            children: [
              // Remove Photo (.photo-picker-remove)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onRemovePhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005140), // var(--color-primary)
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Remove Photo',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Cancel (.photo-picker-cancel)
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB51B00), // var(--color-secondary)
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD9E8E5), // var(--color-page-bg)
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x38000000), // 0 0 28px rgba(0,0,0,0.22)
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 36,
              color: const Color(0xFF005140), // var(--color-primary)
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF181C1A), // var(--color-on-surface)
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
