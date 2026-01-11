import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentHistoryPage extends StatelessWidget {
  const PaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('payments')
            .where('userId', isEqualTo: userId)
            .orderBy('dateDue', descending: true) // recent payments first
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No payment history.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            );
          }

          final payments = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = payments[index].data() as Map<String, dynamic>;

              final categoryName = data['categoryName'] ?? 'Unnamed Category';
              final amount = data['amountOwed'] ?? 0;
              final dueDate = (data['dateDue'] as Timestamp).toDate();
              final status = data['status'] ?? 'Unknown';
              final billingPeriod = data['billingPeriod'] ?? '';
              final proofUploaded = data['proofRef'] != null && (data['proofRef'] as String).isNotEmpty;

              // Status color
              Color statusColor;
              switch (status.toLowerCase()) {
                case 'paid':
                  statusColor = Colors.green;
                  break;
                case 'due':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.orange;
              }

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  title: Text(
                    categoryName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(
                    'Amount: ₱${NumberFormat('#,##0.00').format(amount)} • '
                    'Billing Period: $billingPeriod • '
                    'Due: ${DateFormat('MMM d, yyyy').format(dueDate)}\n'
                    '${proofUploaded ? "Proof uploaded" : "No proof"}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  trailing: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  onTap: () {
                    // Optionally navigate to details / view proof
                    print('Tapped payment history: $categoryName, $billingPeriod');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
