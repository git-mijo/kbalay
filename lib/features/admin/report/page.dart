import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportDueUsersPage extends StatefulWidget {
  const ReportDueUsersPage({super.key});

  @override
  State<ReportDueUsersPage> createState() => _ReportDueUsersPageState();
}

class _ReportDueUsersPageState extends State<ReportDueUsersPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic> _users = {};
  Map<String, dynamic> _paymentCategories = {};

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchPaymentCategories();
  }

  Future<void> _fetchUsers() async {
    final snapshot = await _db.collection('master_residents').get();
    final map = <String, dynamic>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      map[data['userId']] = data;
    }
    setState(() => _users = map);
  }

  Future<void> _fetchPaymentCategories() async {
    final snapshot = await _db.collection('payment_categories').get();
    final map = <String, dynamic>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      map[data['categoryId']] = data;
    }
    setState(() => _paymentCategories = map);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Dues Report'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _users.isEmpty || _paymentCategories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('payments')
                  .where('status', whereIn: ['due', 'Pending', 'pending'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final payments = snapshot.data?.docs ?? [];

                if (payments.isEmpty) {
                  return const Center(
                    child: Text(
                      'No pending or due payments.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  );
                }

                final List<Map<String, dynamic>> paymentList = [];

                for (var doc in payments) {
                  final data = doc.data() as Map<String, dynamic>;
                  final userId = data['userId'];
                  final categoryId = data['categoryId'];

                  final user = _users[userId] ?? {};
                  final category = _paymentCategories[categoryId] ?? {};

                  // Handle due date safely
                  DateTime? dueDate;
                  if (data['dateDue'] is Timestamp) {
                    dueDate = (data['dateDue'] as Timestamp).toDate();
                  } else if (data['dateDue'] is int) {
                    final now = DateTime.now();
                    dueDate = DateTime(now.year, now.month, data['dateDue']);
                  } else if (data['dateDue'] is DateTime) {
                    dueDate = data['dateDue'];
                  } else {
                    dueDate = DateTime.now();
                  }

                  paymentList.add({
                    'paymentId': doc.id,
                    'userId': userId,
                    'firstName': user['firstName'] ?? '',
                    'lastName': user['lastName'] ?? '',
                    'lotId': user['lotId'] ?? '',
                    'profileImageBase64': user['profileImageBase64'] ?? '',
                    'categoryName': category['categoryName'] ?? '',
                    'amount': (data['amountOwed'] ?? category['defaultFee'] ?? 0).toDouble(),
                    'dueDate': dueDate,
                    'status': data['status'] ?? 'Pending',
                  });
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: paymentList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = paymentList[index];

                    Uint8List? userImage;
                    try {
                      final base64Str = item['profileImageBase64'] as String;
                      if (base64Str.isNotEmpty) userImage = base64Decode(base64Str);
                    } catch (_) {
                      userImage = null;
                    }

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.blueAccent,
                            backgroundImage: userImage != null ? MemoryImage(userImage) : null,
                            child: userImage == null
                                ? Text(
                                    item['firstName'].isNotEmpty
                                        ? item['firstName'][0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(color: Colors.white, fontSize: 18),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item['firstName']} ${item['lastName']}',
                                    style:
                                        const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('Lot: ${item['lotId']}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                                const SizedBox(height: 2),
                                Text('Category: ${item['categoryName']}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text('Amount: ₱${(item['amount'] as double).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text(
                                  'Due Date: ${DateFormat('MMM d, yyyy').format(item['dueDate'])}',
                                  style: const TextStyle(fontSize: 12, color: Colors.red),
                                ),
                                const SizedBox(height: 2),
                                Text('Status: ${item['status']}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: item['status'] == 'Due'
                                            ? Colors.red
                                            : Colors.orange)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
