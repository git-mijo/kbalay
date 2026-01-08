import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

/// Quick actions widget for common admin tasks
class QuickActionsWidget extends StatelessWidget {
  final VoidCallback onPaymentManagement;
  final VoidCallback onGenerateReport;
  final VoidCallback onSendNotification;

  const QuickActionsWidget({
    super.key,
    required this.onPaymentManagement,
    required this.onGenerateReport,
    required this.onSendNotification,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.payment,
            label: 'Payment\nManagement',
            color: theme.colorScheme.primary,
            onTap: () {
              HapticFeedback.lightImpact();
              onPaymentManagement();
            },
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _ActionButton(
            icon: Icons.assessment,
            label: 'Generate\nReport',
            color: theme.colorScheme.tertiary,
            onTap: () {
              HapticFeedback.lightImpact();
              onGenerateReport();
            },
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _ActionButton(
            icon: Icons.notifications_active,
            label: 'Announcements',
            color: theme.colorScheme.secondary,
            onTap: () {
              HapticFeedback.lightImpact();
              onSendNotification();
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(2.5.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
