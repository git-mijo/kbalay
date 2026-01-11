import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/resident/payment/pay.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageDuesPage extends StatelessWidget {
  const ManageDuesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Dues'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getUserDuesGrouped(db, userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No pending dues at the moment.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            );
          }

          final groupedDues = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: groupedDues.map((group) {
              final groupName = group['group'];
              final dues = group['items'] as List<Map<String, dynamic>>;

              // Set group header color
              Color groupColor;
              switch (groupName) {
                case 'Paid':
                  groupColor = Colors.green;
                  break;
                case 'Pending Review':
                  groupColor = Colors.orange;
                  break;
                default:
                  groupColor = Colors.redAccent;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: groupColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      groupName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: groupColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dues list
                  ...dues.map((due) {
                    final categoryName = due['categoryName'];
                    final amount = due['amountOwed'];
                    final dueDate = due['dateDue'];
                    final status = due['status'];
                    final billingPeriod = due['billingPeriod'];

                    Color statusColor;
                    switch (status.toLowerCase()) {
                      case 'paid':
                        statusColor = Colors.green;
                        break;
                      case 'pending':
                        statusColor = Colors.orange;
                        break;
                      case 'due':
                        statusColor = Colors.red;
                        break;
                      default:
                        statusColor = Colors.grey;
                    }

                    final frequencyMap = {
                      1: 'Daily',
                      2: 'Weekly',
                      3: 'Monthly',
                      4: 'Yearly',
                      5: 'One-time',
                    };
                    final freqStr = frequencyMap[due['frequency']] ?? 'Unknown';

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        title: Text(
                          categoryName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Amount: ₱${NumberFormat('#,##0.00').format(amount)} • Due: ${DateFormat('MMM d, yyyy').format(dueDate)}',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                // Frequency tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    freqStr,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Status tag
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        onTap: (status.toLowerCase() == 'due' || status.toLowerCase() == 'upcoming' || status.toLowerCase() == 'rejected')
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PayDuesPage(
                                      paymentId: due['categoryId'],
                                      categoryName: categoryName,
                                      amount: amount,
                                      dueDate: dueDate,
                                      billingPeriod: billingPeriod,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    );
                  }).toList(),

                  // Divider between groups
                  const SizedBox(height: 12),
                  const Divider(thickness: 1),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          );

        },
      ),
    );
  }

  /// Get pending dues for the user and group by Paid, Pending, Due/Upcoming
  Future<List<Map<String, dynamic>>> _getUserDuesGrouped(
      FirebaseFirestore db, String? userId) async {
    if (userId == null) return [];

    final now = DateTime.now();

    // 1️⃣ Fetch all active dues
    final activeSnapshot = await db.collection('payment_categories').get();
    final activeDues = activeSnapshot.docs
        .map((d) => d.data())
        .map((d) => {
              'categoryId': d['categoryId'],
              'categoryName': d['categoryName'],
              'defaultFee': d['defaultFee'],
              'dueDayOfMonth': d['dueDayOfMonth'],
              'frequency': d['frequency'] ?? 3, // default monthly
            })
        .toList();

    // 2️⃣ Fetch user payments
    final paymentsSnapshot =
        await db.collection('payments').where('userId', isEqualTo: userId).get();
    final payments = paymentsSnapshot.docs
        .map((d) => d.data())
        .map((p) => {
              'categoryId': p['categoryId'],
              'billingPeriod': p['billingPeriod'],
              'amountOwed': p['amountOwed'],
              'status': p['status'],
              'dateDue': (p['dateDue'] as Timestamp).toDate(),
            })
        .toList();

    List<Map<String, dynamic>> dueList = [];

    for (var due in activeDues) {
      String billingPeriod;
      DateTime dueDate;

      // Compute dueDate & billing period
      if (due['frequency'] == 4) {
        final year = now.year;
        final month = due['dueDayOfMonth'] ?? 1;
        dueDate = DateTime(year, month, 30);
        billingPeriod = DateFormat('yyyy').format(dueDate);
      } else if (due['frequency'] == 3) {
        final year = now.year;
        final month = now.month;
        dueDate = DateTime(year, month, due['dueDayOfMonth']);
        billingPeriod = DateFormat('MMM yyyy').format(dueDate);
      } else if (due['frequency'] == 2) {
        int targetWeekday = due['dueDayOfMonth'] ?? 1;
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday % 7));
        dueDate = startOfWeek.add(Duration(days: targetWeekday));
        if (dueDate.isBefore(now)) {
          dueDate = dueDate.add(const Duration(days: 7));
        }
        billingPeriod = 'Week of ${DateFormat('MMM d, yyyy').format(dueDate)}';
      } else if (due['frequency'] == 5) {
        dueDate = now;
        billingPeriod = DateFormat('MMM d, yyyy').format(dueDate);
      } else {
        final year = now.year;
        final month = now.month;
        dueDate = DateTime(year, month, due['dueDayOfMonth']);
        billingPeriod = DateFormat('MMM yyyy').format(dueDate);
      }

      // Check if user has payment for this category & billingPeriod
      final payment = payments.firstWhere(
          (p) =>
              p['categoryId'] == due['categoryId'] &&
              p['billingPeriod'] == billingPeriod,
          orElse: () => {});

      String status;
      double amountOwed = due['defaultFee']?.toDouble() ?? 0;

      if (payment.isEmpty) {
        if (now.isAfter(dueDate)) {
          status = 'Due';
        } else {
          status = 'Upcoming';
        }
      } else {
        status = (payment['status'] ?? 'Upcoming').toString();
        amountOwed = payment['amountOwed']?.toDouble() ?? amountOwed;
      }

      dueList.add({
        'categoryId': due['categoryId'],
        'frequency': due['frequency'],
        'categoryName': due['categoryName'],
        'amountOwed': amountOwed,
        'dateDue': dueDate,
        'status': status,
        'billingPeriod': billingPeriod,
      });
    }

    // Group by status: Paid, Pending, Due/Upcoming
    final Map<String, List<Map<String, dynamic>>> groupedMap = {
      'Pending Review': [],
      'Due / Upcoming': [],
      'Paid': [],
    };

    for (var d in dueList) {
      final s = d['status'].toLowerCase();
      if (s == 'paid') {
        groupedMap['Paid']!.add(d);
      } else if (s == 'pending') {
        groupedMap['Pending Review']!.add(d);
      } else {
        groupedMap['Due / Upcoming']!.add(d);
      }
    }

    // Return as list for ListView
    return groupedMap.entries
        .map((e) => {'group': e.key, 'items': e.value})
        .toList();
  }
}
