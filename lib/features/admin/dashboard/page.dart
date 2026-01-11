import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_app_bar.dart';
import './widgets/csv_upload.dart';
import './widgets/financial_summary.dart';
import './widgets/metrics_card.dart';
import './widgets/quick_actions.dart';
import './widgets/recent_activity.dart';

/// Admin Dashboard - Central command center for HOA administrators
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Dashboard metrics
  int _totalResidents = 247;
  int _pendingPayments = 18;
  int _recentActivities = 12;
  double _collectionRate = 94.5;

  // CSV upload state
  bool _isUploading = false;
  String? _uploadedFileName;
  List<Map<String, dynamic>> _uploadedData = [];
  String? _uploadError;

  // Recent activities
  final List<Map<String, dynamic>> _recentActivityList = [
    {
      'type': 'resident',
      'title': 'New Resident Registration',
      'description': 'John Smith - Lot 45',
      'timestamp': '2 hours ago',
      'icon': Icons.person_add,
    },
    {
      'type': 'payment',
      'title': 'Payment Received',
      'description': 'Monthly dues - Lot 23',
      'timestamp': '4 hours ago',
      'icon': Icons.payment,
    },
    {
      'type': 'system',
      'title': 'Payment Definition Updated',
      'description': 'Monthly HOA Dues - \$250',
      'timestamp': '1 day ago',
      'icon': Icons.edit,
    },
  ];

  Future<void> _handleCsvUpload() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadError = null;
        _uploadedData.clear();
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.first.bytes == null) {
        setState(() => _isUploading = false);
        return;
      }

      final csvString = utf8.decode(result.files.first.bytes!);
      final rows = const CsvToListConverter(
        shouldParseNumbers: false,
      ).convert(csvString);

      if (rows.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Normalize headers
      final headers = rows.first
          .map((e) => e.toString().trim().toLowerCase())
          .toList();

      const requiredHeaders = [
        'lotid',
        'firstname',
        'lastname',
        'fulladdress',
      ];

      for (final h in requiredHeaders) {
        if (!headers.contains(h)) {
          throw Exception('Missing required column: $h');
        }
      }

      // Parse CSV rows
      final parsed = <Map<String, dynamic>>[];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < headers.length) continue;

        parsed.add({
          'lotId': row[headers.indexOf('lotid')].toString().trim(),
          'firstName': row[headers.indexOf('firstname')].toString().trim(),
          'lastName': row[headers.indexOf('lastname')].toString().trim(),
          'fullAddress': row[headers.indexOf('fulladdress')].toString().trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 🔍 Filter existing residents
      final firestore = FirebaseFirestore.instance;
      final newResidents = <Map<String, dynamic>>[];

      for (final resident in parsed) {
        final exists = await firestore
            .collection('master_residents')
            .where('lotId', isEqualTo: resident['lotId'])
            .limit(1)
            .get();

        if (exists.docs.isEmpty) {
          newResidents.add(resident);
        }
      }

      if (newResidents.isEmpty) {
        setState(() {
          _isUploading = false;
          _uploadError = 'No new residents found to upload.';
        });
        return;
      }

      // 🪟 Confirmation Modal
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirm Upload'),
          content: SizedBox(
            width: double.maxFinite,
            height: 40.h,
            child: ListView.builder(
              itemCount: newResidents.length,
              itemBuilder: (context, index) {
                final r = newResidents[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text('${r['firstName']} ${r['lastName']}'),
                  subtitle: Text(r['fullAddress']),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Upload'),
            ),
          ],
        ),
      );

      if (confirm != true) {
        setState(() => _isUploading = false);
        return;
      }

      // 🚀 Batch upload
      final batch = firestore.batch();
      for (final resident in newResidents) {
        final doc = firestore.collection('master_residents').doc();
        batch.set(doc, resident);
      }
      await batch.commit();

      setState(() {
        _uploadedFileName = result.files.first.name;
        _uploadedData = newResidents;
        _totalResidents += newResidents.length;
        _isUploading = false;
      });

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Uploaded ${newResidents.length} new residents',
            ),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _uploadError = e.toString();
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _navigateToPaymentManagement() {
    Navigator.pushNamed(context, AppRoutes.adminPayment);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Admin Dashboard',
        variant: CustomAppBarVariant.standard,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              HapticFeedback.lightImpact();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics Cards
                Row(
                  children: [
                    Expanded(
                      child: MetricsCardWidget(
                        title: 'Total Residents',
                        value: _totalResidents.toString(),
                        icon: Icons.people,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: MetricsCardWidget(
                        title: 'Pending Payments',
                        value: _pendingPayments.toString(),
                        icon: Icons.pending_actions,
                        color: AppTheme.warningLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: MetricsCardWidget(
                        title: 'Recent Activities',
                        value: _recentActivities.toString(),
                        icon: Icons.notifications_active,
                        color: AppTheme.successLight,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: MetricsCardWidget(
                        title: 'Collection Rate',
                        value: '${_collectionRate.toStringAsFixed(1)}%',
                        icon: Icons.trending_up,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),

                // CSV Upload Section
                Text(
                  'Resident Data Management',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.5.h),
                CsvUploadWidget(),
                SizedBox(height: 3.h),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.5.h),
                QuickActionsWidget(
                  onPaymentManagement: () {
                    Navigator.pushNamed(context, AppRoutes.adminPayment);
                  },
                  onGenerateReport: () {
                    Navigator.pushNamed(context, AppRoutes.adminReports);
                  },
                  onSendNotification: () {
                    Navigator.pushNamed(context, AppRoutes.adminAnnouncement);
                    // HapticFeedback.lightImpact();
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(
                    //     content: Text('Opening notification composer...'),
                    //   ),
                    // );
                  },
                ),
                SizedBox(height: 3.h),

                // Financial Summary
                Text(
                  'Financial Summary',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.5.h),
                FinancialSummaryWidget(
                  totalCollected: 61750.00,
                  pendingAmount: 4500.00,
                  monthlyTarget: 66250.00,
                ),
                SizedBox(height: 3.h),

                // Recent Activities
                Text(
                  'Recent Activities',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.5.h),
                RecentActivityWidget(activities: _recentActivityList),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
