import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Individual onboarding page widget
///
/// Displays a single onboarding screen with:
/// - Full-screen illustration
/// - Headline and description
/// - Consistent layout across all pages
class OnboardingPageWidget extends StatelessWidget {
  const OnboardingPageWidget({
    super.key,
    required this.imageUrl,
    required this.semanticLabel,
    required this.title,
    required this.description,
  });

  final String imageUrl;
  final String semanticLabel;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            // CustomImageWidget(
            //   imageUrl: imageUrl,
            //   width: 80.w,
            //   height: 35.h,
            //   fit: BoxFit.contain,
            //   semanticLabel: semanticLabel,
            // ),
            SizedBox(height: 6.h),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),

            // Description
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
