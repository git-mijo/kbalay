import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

/// CSV upload widget with drag-and-drop interface
class CsvUploadWidget extends StatelessWidget {
  final bool isUploading;
  final String? uploadedFileName;
  final int uploadedCount;
  final String? errorMessage;
  final VoidCallback onUpload;

  const CsvUploadWidget({
    super.key,
    required this.isUploading,
    this.uploadedFileName,
    required this.uploadedCount,
    this.errorMessage,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: errorMessage != null
              ? theme.colorScheme.error
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 2.0,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            uploadedFileName != null ? Icons.check_circle : Icons.upload_file,
            size: 32.sp,
            color: uploadedFileName != null
                ? theme.colorScheme.tertiary
                : theme.colorScheme.primary,
          ),
          SizedBox(height: 2.h),
          Text(
            uploadedFileName ?? 'Upload Resident Data (CSV)',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            uploadedFileName != null
                ? '$uploadedCount residents uploaded successfully'
                : 'Required columns: lotId, firstName, lastName, fullAddress',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          // if (errorMessage != null) ..[
          //   SizedBox(height: 1.h),
          //   Text(
          //     errorMessage!,
          //     style: GoogleFonts.inter(
          //       fontSize: 12.sp,
          //       fontWeight: FontWeight.w500,
          //       color: theme.colorScheme.error,
          //     ),
          //     textAlign: TextAlign.center,
          //   ),
          // ],
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isUploading ? null : () {
                HapticFeedback.lightImpact();
                onUpload();
              },
              icon: isUploading
                  ? SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Icon(Icons.file_upload),
              label: Text(isUploading ? 'Uploading...' : 'Select CSV File'),
            ),
          ),
        ],
      ),
    );
  }
}
