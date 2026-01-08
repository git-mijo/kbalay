import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hoa/features/admin/payment/services/payment_service.dart';
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

  List<Map<String, dynamic>> _paymentDefinitions = [];

  Future<void> loadPaymentDefinitions() async {
    _paymentDefinitions = await PaymentService().fetchPaymentCategories();
    setState(() {});
  }

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
    loadPaymentDefinitions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addPaymentDefinition() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final descriptionController = TextEditingController();
        final amountController = TextEditingController();
        final dueDayController = TextEditingController();
        String selectedFrequency = 'Monthly';
        bool isEnabled = false;

        // Frequency mapping
        final Map<String, int> frequencyMap = {
          'Daily': 1,
          'Weekly': 2,
          'Monthly': 3,
          'Yearly': 4,
          'One-time': 5,
        };

        return StatefulBuilder(
          builder: (context, setState) {
            String? validateDueDay(String value) {
              if (value.isEmpty) return "Required";

              final number = int.tryParse(value);
              if (number == null) return "Must be a number";

              if (selectedFrequency == 'Monthly') {
                if (number < 1 || number > 31) return "Enter 1–31";
              }

              if (selectedFrequency == 'Yearly') {
                if (number < 1 || number > 12) return "Enter 1–12";
              }

              return null; // valid
            }

            return AlertDialog(
              title: const Text('Create new Payment Definition'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    SizedBox(height: 2.h),

                    // Description
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    SizedBox(height: 2.h),

                    // Amount
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 2.h),

                    // Frequency dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedFrequency,
                      decoration:
                          const InputDecoration(labelText: 'Frequency'),
                      items: frequencyMap.keys
                        .map(
                          (freq) => DropdownMenuItem(
                            value: freq,
                            child: Text(freq),
                          ),
                        )
                        .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedFrequency = value;
                          dueDayController.text = '';
                        });
                      },
                    ),
                    SizedBox(height: 2.h),

                    // Due Day / Month
                    if (selectedFrequency == 'Monthly')
                      TextField(
                        controller: dueDayController,
                        decoration: const InputDecoration(labelText: 'Day of Month (1-31)'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    if (selectedFrequency == 'Yearly')
                      TextField(
                        controller: dueDayController,
                        decoration: const InputDecoration(labelText: 'Month (1-12)'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                      ),
                    SizedBox(height: 2.h),

                    // isEnabled switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Active'),
                        Switch(
                          value: isEnabled,
                          onChanged: (value) {
                            setState(() {
                              isEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {

                    final error = validateDueDay(dueDayController.text);

                    if ((selectedFrequency == 'Monthly' || selectedFrequency == 'Yearly') && error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                      return;
                    }

                    final docRef = FirebaseFirestore.instance
                      .collection('payment_categories')
                      .doc(); // auto-generated id

                    await docRef.set({
                      'categoryId': docRef.id,
                      'categoryName': nameController.text,
                      'categoryDescription': descriptionController.text,
                      'defaultFee': double.tryParse(amountController.text) ?? 0,
                      'frequency': frequencyMap[selectedFrequency],
                      'dueDayOfMonth': int.tryParse(dueDayController.text) ?? 0,
                      'isEnabled': isEnabled,
                    });

                    // Close dialog
                    Navigator.of(context, rootNavigator: true).pop();

                    await loadPaymentDefinitions();

                    // Optional: show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New Payment definition created')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editPaymentDefinition(String id) async {
    final data = _paymentDefinitions.firstWhere((def) => def['id'] == id);
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: data['name']);
        final descriptionController =
            TextEditingController(text: data['description']);
        final amountController =
            TextEditingController(text: data['amount'].toString());

        // Frequency mapping
        final Map<String, int> frequencyMap = {
          'Daily': 1,
          'Weekly': 2,
          'Monthly': 3,
          'Yearly': 4,
          'One-time': 5,
        };

        // Reverse map for initial value
        String selectedFrequency = frequencyMap.entries
            .firstWhere(
                (e) => e.value == int.tryParse(data['frequencyId'].toString()),
                orElse: () => const MapEntry('Monthly', 3))
            .key;

        final dueDayController = TextEditingController(text: data['dueTime'].toString());
        bool isEnabled = data['isActive'] ?? false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Payment Definitionz'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    SizedBox(height: 2.h),

                    // Description
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    SizedBox(height: 2.h),

                    // Amount
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 2.h),

                    // Frequency dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedFrequency,
                      decoration:
                          const InputDecoration(labelText: 'Frequency'),
                      items: frequencyMap.keys
                        .map(
                          (freq) => DropdownMenuItem(
                            value: freq,
                            child: Text(freq),
                          ),
                        )
                        .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedFrequency = value;
                          dueDayController.text = '';
                        });
                      },
                    ),
                    SizedBox(height: 2.h),

                    // Due Day / Month
                    if (selectedFrequency == 'Monthly')
                      TextField(
                        controller: dueDayController,
                        decoration: const InputDecoration(
                            labelText: 'Day of Month (1-31)'),
                        keyboardType: TextInputType.number,
                      ),
                    if (selectedFrequency == 'Yearly')
                      TextField(
                        controller: dueDayController,
                        decoration: const InputDecoration(
                            labelText: 'Month (1-12)'),
                        keyboardType: TextInputType.number,
                      ),

                    SizedBox(height: 2.h),

                    // isEnabled switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Active'),
                        Switch(
                          value: isEnabled,
                          onChanged: (value) {
                            setState(() {
                              isEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Update Firestore
                    await PaymentService().updatePaymentCategory(id, {
                      'categoryName': nameController.text,
                      'categoryDescription': descriptionController.text,
                      'defaultFee': double.tryParse(amountController.text) ?? 0,
                      'frequency': frequencyMap[selectedFrequency],
                      'dueDayOfMonth': int.tryParse(dueDayController.text) ?? 0,
                      'isEnabled': isEnabled,
                    });

                    // Close dialog
                    Navigator.of(context, rootNavigator: true).pop();

                    await loadPaymentDefinitions();

                    // Optional: show confirmation
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment definition updated')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // void _editPaymentDefinition(String id) {
  //   HapticFeedback.lightImpact();
  //   ScaffoldMessenger.of(
  //     context,
  //   ).showSnackBar(SnackBar(content: Text('Editing payment definition: $id')));
  // }

  Future<void> _deletePaymentDefinition(String id) async {
    HapticFeedback.mediumImpact();


    try {
      await PaymentService().deletePaymentCategory(id);
      await loadPaymentDefinitions();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment definition deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
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
                    onEdit: (String id) async {
                      await _editPaymentDefinition(id);
                      await loadPaymentDefinitions();
                    },
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
