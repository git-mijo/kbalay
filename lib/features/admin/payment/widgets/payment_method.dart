import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_hoa/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// Payment methods tab widget
class PaymentMethodsTabWidget extends StatelessWidget {
  final List<Map<String, dynamic>> methods;
  final Function(String, bool) onToggle;

  const PaymentMethodsTabWidget({
    super.key,
    required this.methods,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: methods.length,
      itemBuilder: (context, index) {
        final method = methods[index];
        final isEnabled = method['isEnabled'] as bool;

        return Card(
          margin: EdgeInsets.only(bottom: 2.h),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.colorScheme.outline.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(
                        method['icon'] as IconData,
                        color: isEnabled
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Text(
                            method['description'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isEnabled,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        onToggle(method['id'] as String, value);
                      },
                      activeThumbColor: AppTheme.successLight,
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Processing Fee',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${(method['processingFee'] as double).toStringAsFixed(1)}%',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Processing Time',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            method['processingTime'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isEnabled) ...[
                  SizedBox(height: 1.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: AppTheme.warningLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16.sp,
                          color: AppTheme.warningLight,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            'This payment method is currently disabled',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.warningLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}