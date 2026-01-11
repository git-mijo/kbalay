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

  String formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    return DateFormat('MMM d, yyyy').format(ts.toDate());
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
              stream: _db.collection('payments').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Map of payments by userId + categoryId
                final payments = snapshot.data?.docs ?? [];
                final Map<String, Map<String, dynamic>> paymentMap = {};
                for (var doc in payments) {
                  final data = doc.data() as Map<String, dynamic>;
                  paymentMap['${data['userId']}_${data['categoryId']}'] = data;
                }

                final now = DateTime.now();

                // Prepare list of users with unpaid dues
                final List<Map<String, dynamic>> usersWithDue = [];

                for (var userId in _users.keys) {
                  final user = _users[userId];

                  for (var categoryId in _paymentCategories.keys) {
                    final category = _paymentCategories[categoryId];

                    // Compute current due date
                    DateTime dueDate;
                    final day = category['dueDayOfMonth'] ?? 1;
                    final freq = category['frequency'] ?? 3;

                    if (freq == 4) {
                      // yearly
                      dueDate = DateTime(now.year, day, 1);
                    } else if (freq == 3) {
                      // monthly
                      dueDate = DateTime(now.year, now.month, day);
                    } else {
                      // weekly/one-time/daily fallback
                      dueDate = now;
                    }

                    if (dueDate.isAfter(now)) continue; // not due yet

                    final key = '${userId}_${categoryId}';
                    if (!paymentMap.containsKey(key)) {
                      // User has NOT submitted payment for this due category
                      usersWithDue.add({
                        'userId': userId,
                        'firstName': user['firstName'] ?? '',
                        'lastName': user['lastName'] ?? '',
                        'lotId': user['lotId'] ?? '',
                        'profileImageBase64': user['profileImageBase64'] ?? '',
                        'categoryName': category['categoryName'] ?? '',
                        'amount': category['defaultFee']?.toDouble() ?? 0,
                        'dueDate': dueDate,
                      });
                    }
                  }
                }

                if (usersWithDue.isEmpty) {
                  return const Center(
                    child: Text(
                      'No pending dues for any user.',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  );
                }

                // Sort by due date ascending
                usersWithDue.sort((a, b) => (a['dueDate'] as DateTime).compareTo(b['dueDate'] as DateTime));

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: usersWithDue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final userDue = usersWithDue[index];

                    Uint8List? userImage;
                    try {
                      final base64Str = userDue['profileImageBase64'] as String;
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
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
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
                                    userDue['firstName'].isNotEmpty
                                        ? userDue['firstName'][0].toUpperCase()
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
                                Text(
                                  '${userDue['firstName']} ${userDue['lastName']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text('Lot: ${userDue['lotId']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                const SizedBox(height: 2),
                                Text('Category: ${userDue['categoryName']}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text('Amount: ₱${(userDue['amount'] as double).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                const SizedBox(height: 2),
                                Text('Due Date: ${DateFormat('MMM d, yyyy').format(userDue['dueDate'])}', style: const TextStyle(fontSize: 12, color: Colors.red)),
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
