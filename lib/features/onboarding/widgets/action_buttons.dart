import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

class ActionButtonsWidget extends StatelessWidget {
  const ActionButtonsWidget({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.onSkip,
    required this.onNext,
    required this.onGetStarted,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = currentPage == pageCount - 1;

    return Column(
      children: [
        // Skip button
        if (!isLastPage)
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                onSkip();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              ),
              child: Text(
                'Skip',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

        const Spacer(),

        // Next/Get Started button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              isLastPage ? onGetStarted() : onNext();
            },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: Text(
              isLastPage ? 'Get Started' : 'Next',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontSize: 16.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
