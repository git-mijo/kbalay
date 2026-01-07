import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_app_bar.dart';
import './widgets/payment_definition.dart';
import './widgets/payment_method.dart';

/// Payment Management Screen - Configure payment definitions and methods
class PaymentManagement extends StatefulWidget {
  const PaymentManagement({super.key});

  @override
  State<PaymentManagement> createState() => _PaymentManagementState();
}

class _PaymentManagementState extends State<PaymentManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Payment definitions data
  final List<Map<String, dynamic>> _paymentDefinitions = [
    {
      'id': '1',
      'name': 'Monthly HOA Dues',
      'description': 'Regular monthly community maintenance fees',
      'amount': 250.00,
      'frequency': 'Monthly',
      'dueDay': 1,
      'gracePeriod': 5,
      'lateFee': 25.00,
      'applicableUnits': 'All',
      'isActive': true,
    },
    {
      'id': '2',
      'name': 'Special Assessment',
      'description': 'Community pool renovation project',
      'amount': 500.00,
      'frequency': 'One-time',
      'dueDay': 15,
      'gracePeriod': 10,
      'lateFee': 50.00,
      'applicableUnits': 'All',
      'isActive': true,
    },
    {
      'id': '3',
      'name': 'Amenity Fee',
      'description': 'Clubhouse and gym access',
      'amount': 50.00,
      'frequency': 'Monthly',
      'dueDay': 1,
      'gracePeriod': 5,
      'lateFee': 10.00,
      'applicableUnits': 'Premium',
      'isActive': true,
    },
  ];

  // Payment methods data
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': '1',
      'name': 'Credit/Debit Card',
      'description': 'Visa, Mastercard, American Express',
      'processingFee': 2.9,
      'processingTime': 'Instant',
      'isEnabled': true,
      'icon': Icons.credit_card,
    },
    {
      'id': '2',
      'name': 'ACH Bank Transfer',
      'description': 'Direct bank account transfer',
      'processingFee': 0.5,
      'processingTime': '2-3 business days',
      'isEnabled': true,
      'icon': Icons.account_balance,
    },
    {
      'id': '3',
      'name': 'Check Payment',
      'description': 'Mail physical check to HOA office',
      'processingFee': 0.0,
      'processingTime': '5-7 business days',
      'isEnabled': true,
      'icon': Icons.receipt_long,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addPaymentDefinition() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening payment definition form...')),
    );
  }

  void _editPaymentDefinition(String id) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Editing payment definition: $id')));
  }

  void _deletePaymentDefinition(String id) {
    HapticFeedback.mediumImpact();
    setState(() {
      _paymentDefinitions.removeWhere((def) => def['id'] == id);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment definition deleted')));
  }

  void _togglePaymentMethod(String id, bool enabled) {
    HapticFeedback.lightImpact();
    setState(() {
      final method = _paymentMethods.firstWhere((m) => m['id'] == id);
      method['isEnabled'] = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Payment Management',
        variant: CustomAppBarVariant.withBackButton,
        onBackPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: theme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                labelStyle: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                ),
                tabs: const [
                  Tab(text: 'Payment Definitions'),
                  Tab(text: 'Payment Methods'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  PaymentDefinitionTabWidget(
                    definitions: _paymentDefinitions,
                    onAdd: _addPaymentDefinition,
                    onEdit: _editPaymentDefinition,
                    onDelete: _deletePaymentDefinition,
                  ),
                  PaymentMethodsTabWidget(
                    methods: _paymentMethods,
                    onToggle: _togglePaymentMethod,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
