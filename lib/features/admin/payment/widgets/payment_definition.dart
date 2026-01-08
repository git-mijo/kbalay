import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hoa/features/admin/payment/services/payment_service.dart';
import 'package:flutter_hoa/theme/app_theme.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

/// Payment definitions tab widget
class PaymentDefinitionTabWidget extends StatelessWidget {
  final List<Map<String, dynamic>> definitions;
  final VoidCallback onAdd;
  final Function(String) onEdit;
  final Function(String) onDelete;

  const PaymentDefinitionTabWidget({
    super.key,
    required this.definitions,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(3.w),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onAdd();
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Payment Definition'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            itemCount: definitions.length,
            itemBuilder: (context, index) {
              final definition = definitions[index];
              return Card(
                margin: EdgeInsets.only(bottom: 2.h),
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  definition['name'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  definition['description'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.5.h,
                            ),
                            decoration: BoxDecoration(
                              color: (definition['isActive'] as bool)
                                  ? AppTheme.successLight.withValues(alpha: 0.1)
                                  : theme.colorScheme.outline.withValues(
                                      alpha: 0.1,
                                    ),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              (definition['isActive'] as bool)
                                  ? 'Active'
                                  : 'Inactive',
                              style: GoogleFonts.inter(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: (definition['isActive'] as bool)
                                    ? AppTheme.successLight
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              label: 'Amount',
                              value:
                                  '\₱${(definition['amount'] as double).toStringAsFixed(2)}',
                            ),
                          ),
                          Expanded(
                            child: _InfoItem(
                              label: 'Frequency',
                              value: definition['frequency'] as String,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              label: 'Due Day',
                              value: '${definition['dueDay']}',
                            ),
                          ),
                        ],
                      ),
                      // SizedBox(height: 1.h),
                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: _InfoItem(
                      //         label: 'Late Fee',
                      //         value:
                      //             '\$${(definition['lateFee'] as double).toStringAsFixed(2)}',
                      //       ),
                      //     ),
                      //     Expanded(
                      //       child: _InfoItem(
                      //         label: 'Applicable Units',
                      //         value: definition['applicableUnits'] as String,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onEdit(definition['id'] as String);
                                // onEditPayment(context, definition['id'] as String, definition);
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit'),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                _showDeleteConfirmation(
                                  context,
                                  definition['id'] as String,
                                  definition['name'] as String,
                                );
                              },
                              icon: Icon(
                                Icons.delete,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              label: Text(
                                'Delete',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void onEditPayment(BuildContext context, String id, Map<String, dynamic> data) {
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
                (e) => e.value == int.tryParse(data['frequency'] ?? '0'),
                orElse: () => const MapEntry('Monthly', 3))
            .key;

        final dueDayController =
            TextEditingController(text: data['dueDay']?.toString() ?? '');
        bool isEnabled = data['isActive'] ?? false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Payment Definition'),
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

                          // Reset dueDay if frequency changes
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
                      'dueDayOfMonth':
                          int.tryParse(dueDayController.text) ?? 0,
                      'isEnabled': isEnabled,
                    });

                    Navigator.pop(context);
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

  void _showDeleteConfirmation(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Definition'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(id);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 0.3.h),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
