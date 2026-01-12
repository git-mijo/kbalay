import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/admin/payment/widgets/payment_detail.dart';
import 'package:intl/intl.dart';

class ReviewPaymentsTabWidget extends StatefulWidget {
  const ReviewPaymentsTabWidget({super.key});

  @override
  State<ReviewPaymentsTabWidget> createState() =>
      _ReviewPaymentsTabWidgetState();
}

class _ReviewPaymentsTabWidgetState extends State<ReviewPaymentsTabWidget> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> _fetchPaymentCategories() async {
    // Fetch all request types once
    final snapshot = await FirebaseFirestore.instance.collection('payment_categories').get();
    final Map<String, dynamic> typeMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      typeMap[data['categoryId']] = data;
    }
    return typeMap;
  }

  // Fetch all users once
  Future<Map<String, dynamic>> _fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('master_residents').get();
    final Map<String, dynamic> userMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      userMap[data['userId']] = data;
    }
    return userMap;
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Future.wait([
        _fetchPaymentCategories(),
        _fetchUsers(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final paymentTypeMap = snapshot.data![0];
        final userMap = snapshot.data![1];

        String formatTimestamp(Timestamp? ts) {
          if (ts == null) return '';
          final date = ts.toDate();
          return DateFormat('MMM d, yyyy – hh:mm a').format(date); 
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('payments')
              .where('status', isEqualTo: 'Pending')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No payments pending review.',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              );
            }

            final payments = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              data['paymentId'] = doc.id; // keep document ID
              return data;
            }).toList();

            // Sort by submittedAt descending
            payments.sort((a, b) {
              final aTime = a['submittedAt'] as Timestamp?;
              final bTime = b['submittedAt'] as Timestamp?;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime); // most recent first
            });

            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: payments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final data = payments[index];

                final userData = userMap[data['userId']] ?? {};
                final typeData = paymentTypeMap[data['categoryId']] ?? {};

                final amount = typeData['defaultFee']?.toDouble() ?? 0;
                final billingPeriod = data['billingPeriod'] ?? '';
                final frequencyMap = {1: 'Daily', 2: 'Weekly', 3: 'Monthly', 4: 'Yearly', 5: 'One-time'};
                final frequency = frequencyMap[typeData['frequency']] ?? 'Unknown';
                final lotId = userData['lotId'] ?? '';
                final firstName = userData['firstName'] ?? '';
                final lastName = userData['lastName'] ?? '';
                final categoryName = typeData['categoryName'] ?? '';

                final String? base64String = userData['profileImageBase64'] as String?;
                final Uint8List? userImage = base64String != null && base64String.isNotEmpty
                    ? base64Decode(base64String)
                    : null;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentDetailPage(
                          paymentData: data,
                          userData: userData,
                          typeData: typeData,
                        ),
                      ),
                    );
                    // Optional: navigate to detailed review page
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: User photo
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.lightBlueAccent,
                          backgroundImage: userImage != null
                              ? MemoryImage(userImage)
                              : null,
                          child: userImage == null
                            ? Text(
                              userData['firstName'].isNotEmpty ? userData['firstName'][0].toUpperCase() : "U",
                              style: const TextStyle(color: Colors.white, fontSize: 20),
                            )
                          : null,
                        ),
                        const SizedBox(width: 12),

                        // Right: User info & Payment info
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left column: Name & Lot
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$firstName $lastName',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Lot: $lotId', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    const SizedBox(height: 2),
                                    Text('Billing Period: $billingPeriod', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                  ],
                                ),
                              ),

                              // Right column: Payment details
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(categoryName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            frequency,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text('₱${amount.toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatTimestamp(data['submittedAt']).toString(),
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );


              },
            );

                        
          },
        );
      
      },
    );
  }

  Future<void> _approvePayment(String docId) async {
    await _db.collection('payments').doc(docId).update({'status': 'Paid'});
  }

  Future<void> _rejectPayment(String docId) async {
    await _db.collection('payments').doc(docId).update({'status': 'Rejected'});
  }
}
