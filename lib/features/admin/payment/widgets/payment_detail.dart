import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentDetailPage extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> typeData;

  const PaymentDetailPage({
    super.key,
    required this.paymentData,
    required this.userData,
    required this.typeData,
  });

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _loading = false;

  /// Update payment status (Paid / Rejected)
  Future<void> _updateStatus(String status) async {
    if (widget.paymentData['paymentId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid payment ID')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _db
          .collection('payments')
          .doc(widget.paymentData['paymentId'])
          .update({'status': status});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment $status successfully')),
      );

      Navigator.pop(context, true); // go back and refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.paymentData;
    final user = widget.userData;
    final type = widget.typeData;

    final firstName = user['firstName'] ?? '';
    final lastName = user['lastName'] ?? '';
    final lotId = user['lotId'] ?? '';
    final categoryName = type['categoryName'] ?? '';
    final amount = type['defaultFee']?.toDouble() ?? 0;
    final billingPeriod = payment['billingPeriod'] ?? '';
    final frequencyMap = {1: 'Daily', 2: 'Weekly', 3: 'Monthly', 4: 'Yearly', 5: 'One-time'};
    final frequency = frequencyMap[type['frequency']] ?? 'Unknown';

    // Handle submittedAt timestamp safely
    DateTime? submittedAt;
    if (payment['submittedAt'] is Timestamp) {
      submittedAt = (payment['submittedAt'] as Timestamp).toDate();
    } else if (payment['submittedAt'] is DateTime) {
      submittedAt = payment['submittedAt'];
    }

    // Handle due date safely
    DateTime? dateDue;
    if (payment['dateDue'] is Timestamp) {
      dateDue = (payment['dateDue'] as Timestamp).toDate();
    } else if (payment['dateDue'] is int) {
      final now = DateTime.now();
      dateDue = DateTime(now.year, now.month, payment['dateDue']);
    } else if (payment['dateDue'] is DateTime) {
      dateDue = payment['dateDue'];
    }

    // Decode proof image
    Uint8List? proofImage;
    final proofBase64 = payment['proofRef'] ?? '';
    if (proofBase64.isNotEmpty) {
      try {
        proofImage = base64Decode(proofBase64);
      } catch (_) {
        proofImage = null;
      }
    }

    // Decode user image
    Uint8List? userImage;
    final photoBase64 = user['profileImageBase64'] ?? '';
    if (photoBase64.isNotEmpty) {
      try {
        userImage = base64Decode(photoBase64);
      } catch (_) {
        userImage = null;
      }
    }

    String formatDate(DateTime? dt) {
      if (dt == null) return '-';
      return DateFormat('MMM d, yyyy – hh:mm a').format(dt);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.blueAccent.shade100,
                  backgroundImage: userImage != null ? MemoryImage(userImage) : null,
                  child: userImage == null
                      ? Text(
                          firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                          style: const TextStyle(color: Colors.white, fontSize: 24),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$firstName $lastName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 2),
                      Text('Lot: $lotId', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Payment info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Category', categoryName),
                  _buildInfoRow('Amount', '₱${amount.toStringAsFixed(2)}'),
                  _buildInfoRow('Frequency', frequency),
                  _buildInfoRow('Billing Period', billingPeriod),
                  _buildInfoRow('Due Date', formatDate(dateDue)),
                  _buildInfoRow('Submitted At', formatDate(submittedAt)),
                  _buildInfoRow('Status', payment['status'] ?? 'Pending'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Proof of payment
            if (proofImage != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Proof of Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        proofImage,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            if (proofImage == null)
              const Text('No proof of payment uploaded', style: TextStyle(color: Colors.black54)),

            const SizedBox(height: 24),

            // Approve / Reject buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _updateStatus('Paid'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, minimumSize: const Size.fromHeight(50)),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Approve', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : () => _updateStatus('Rejected'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size.fromHeight(50)),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Reject', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
