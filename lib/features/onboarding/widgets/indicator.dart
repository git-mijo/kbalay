import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Page indicator dots widget
///
/// Shows progress through onboarding screens with:
/// - Animated dot transitions
/// - Active/inactive states
/// - Smooth color changes
class PageIndicatorWidget extends StatelessWidget {
  const PageIndicatorWidget({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: 1.w),
          width: currentPage == index ? 8.w : 2.w,
          height: 1.h,
          decoration: BoxDecoration(
            color: currentPage == index
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4.0),
          ),
        ),
      ),
    );
  }
}
