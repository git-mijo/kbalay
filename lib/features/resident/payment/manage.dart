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
                            // Row(
                            //   children: [
                            //     // Frequency tag
                            //     Container(
                            //       padding: const EdgeInsets.symmetric(
                            //           horizontal: 8, vertical: 2),
                            //       decoration: BoxDecoration(
                            //         color: Colors.blue.shade100,
                            //         borderRadius: BorderRadius.circular(12),
                            //       ),
                            //       child: Text(
                            //         freqStr,
                            //         style: const TextStyle(
                            //           fontSize: 10,
                            //           fontWeight: FontWeight.bold,
                            //           color: Colors.blueAccent,
                            //         ),
                            //       ),
                            //     ),
                            //     const Spacer(),
                            //     // Status tag
                            //     Container(
                            //       padding: const EdgeInsets.symmetric(
                            //           horizontal: 8, vertical: 2),
                            //       decoration: BoxDecoration(
                            //         color: statusColor.withOpacity(0.15),
                            //         borderRadius: BorderRadius.circular(12),
                            //       ),
                            //       child: Text(
                            //         status,
                            //         style: TextStyle(
                            //           fontSize: 10,
                            //           fontWeight: FontWeight.bold,
                            //           color: statusColor,
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                        onTap: (status.toLowerCase() == 'due' || status.toLowerCase() == 'upcoming' || status.toLowerCase() == 'rejected')
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PayDuesPage(
                                      paymentId: due['paymentId'],
                                      categoryId: due['categoryId'],
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

Future<List<Map<String, dynamic>>> _getUserDuesGrouped(
    FirebaseFirestore db, String? userId) async {
  if (userId == null) return [];

  final now = DateTime.now();

  // 1️⃣ Get categories
  final categorySnapshot = await db
    .collection('payment_categories')
    .where('dueDayOfMonth', isLessThanOrEqualTo: now.day)
    .get();

  final categories = categorySnapshot.docs.map((d) {
    final data = d.data();
    return {
      'categoryId': data['categoryId'],
      'categoryName': data['categoryName'],
      'defaultFee': (data['defaultFee'] ?? 0).toDouble(),
      'dueDayOfMonth': data['dueDayOfMonth'] ?? 1,
    };
  }).toList();

  // 2️⃣ Get user payments
  final paymentsSnapshot =
      await db.collection('payments').where('userId', isEqualTo: userId).get();

  if(paymentsSnapshot.docs.isEmpty) return [];

  final payments = paymentsSnapshot.docs.map((p) {
    final data = p.data();
    DateTime dateDue;

    if (data['dateDue'] is Timestamp) {
      dateDue = (data['dateDue'] as Timestamp).toDate();
    } else if (data['dateDue'] is int) {
      dateDue = DateTime(now.year, now.month, data['dateDue']);
    } else {
      dateDue = now;
    }

    return {
      'paymentId': p.id, // Firestore document ID
      'categoryId': data['categoryId'],
      'billingPeriod': data['billingPeriod'],
      'amountOwed': (data['amountOwed'] ?? 0).toDouble(),
      'status': (data['status'] ?? 'Upcoming').toString(),
      'dateDue': dateDue,
    };
  }).toList();

  List<Map<String, dynamic>> dueList = [];

  // 3️⃣ Generate dues list for each category
  for (var cat in categories) {
    final categoryId = cat['categoryId'];
    final categoryName = cat['categoryName'];
    final defaultFee = cat['defaultFee'];
    final dueDay = cat['dueDayOfMonth'];

    final dueDate = DateTime(now.year, now.month, dueDay);

    // Billing period in Firestore format "YYYY-MM"
    final billingPeriod =
        '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}';

    // Find existing payment if any
    Map<String, dynamic>? existingPayment;
    try {
      existingPayment = payments.firstWhere(
        (p) =>
            p['categoryId'] == categoryId &&
            p['billingPeriod'] == billingPeriod,
      );
    } catch (_) {
      existingPayment = null;
    }

    String status;
    double amountOwed = defaultFee;
    String? paymentId;

    if (existingPayment == null) {
      status = now.isAfter(dueDate) ? 'Due' : 'Upcoming';
      paymentId = null;
    } else {
      status = existingPayment['status'] ?? 'Upcoming';
      amountOwed = existingPayment['amountOwed'] ?? defaultFee;
      paymentId = existingPayment['paymentId'];
    }

    dueList.add({
      'paymentId': paymentId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'billingPeriod': billingPeriod,
      'amountOwed': amountOwed,
      'dateDue': dueDate,
      'status': status,
    });
  }

  // 4️⃣ Group dues for UI
  final Map<String, List<Map<String, dynamic>>> grouped = {
    'Pending Review': [],
    'Due Payments': [],
    'Paid': [],
  };

  for (var item in dueList) {
    final s = item['status'].toLowerCase();
    if (s == 'paid') {
      grouped['Paid']!.add(item);
    } else if (s == 'pending' || s == 'pending review') {
      grouped['Pending Review']!.add(item);
    } else {
      grouped['Due / Upcoming']!.add(item);
    }
  }

  return grouped.entries
      .map((e) => {'group': e.key, 'items': e.value})
      .toList();
}

  
}
