import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../../widgets/custom_icon_widget.dart';

/// Biometric authentication widget showing platform-specific
/// biometric options (Face ID, Touch ID, Fingerprint)
class BiometricAuthWidget extends StatelessWidget {
  const BiometricAuthWidget({super.key, required this.onBiometricAuth});

  final VoidCallback onBiometricAuth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Don't show biometric option on web
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: theme.colorScheme.outline, thickness: 1),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'OR',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: theme.colorScheme.outline, thickness: 1),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline, width: 1),
          ),
          child: Column(
            children: [
              Text(
                'Quick Sign In',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 2.h),
              InkWell(
                onTap: onBiometricAuth,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CustomIconWidget(
                      iconName: defaultTargetPlatform == TargetPlatform.iOS
                          ? 'face'
                          : 'fingerprint',
                      color: theme.colorScheme.primary,
                      size: 8.w,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                defaultTargetPlatform == TargetPlatform.iOS
                    ? 'Face ID'
                    : 'Fingerprint',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
