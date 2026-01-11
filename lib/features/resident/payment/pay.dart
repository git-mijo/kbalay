import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/authentication/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PayDuesPage extends StatefulWidget {
  final String paymentId;
  final String categoryName;
  final double amount;
  final DateTime dueDate;
  final String billingPeriod;

  const PayDuesPage({
    super.key,
    required this.paymentId,
    required this.categoryName,
    required this.amount,
    required this.dueDate,
    required this.billingPeriod,
  });

  @override
  State<PayDuesPage> createState() => _PayDuesPageState();
}

class _PayDuesPageState extends State<PayDuesPage> {
  String _proofFile = '';
  bool _loading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProof() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40, // compress image
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);
      setState(() => _proofFile = base64Image);
    }
  }


  Future<void> _submitPayment() async {

    if (_proofFile == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload proof of payment')),
      );
      return;
    }

    setState(() => _loading = true);

    try {

      final snapshot = await FirebaseFirestore.instance
        .collection('master_residents')
        .where('userId', isEqualTo: AuthService().currentUser!.uid)
        .limit(1)
        .get();

        if (snapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to proceed')),
          );
          return;
        }

      final userData = snapshot.docs.first.data();

      await FirebaseFirestore.instance.collection('payments').add({
        'lotId': userData['lotId'],
        'userId': AuthService().currentUser!.uid,
        'categoryId': widget.paymentId,
        'billingPeriod': widget.billingPeriod,
        'amountOwed': widget.amount,
        'dateDue': widget.dueDate,
        'proofRef': _proofFile,
        'status': 'Pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment submitted successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit payment')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    Uint8List? imageBytes = _proofFile != ''
              ? base64Decode(_proofFile)
              : null;
              
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Dues'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Selected pending due
            ListTile(
              title: Text(widget.categoryName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Amount: ₱${widget.amount.toStringAsFixed(2)} • Due: ${widget.billingPeriod}'),
              leading: const Icon(Icons.receipt_long, color: Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            

            // Upload proof container
            InkWell(
              onTap: _pickProof,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.grey.shade400, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                ),
                child : _proofFile == ''
                    ? Container(
                        height: 90,
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: const Icon(Icons.upload_file, size: 40, color: Colors.grey),
                      )
                    : Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        image: imageBytes != null
                            ? DecorationImage(
                                image: MemoryImage(imageBytes),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: imageBytes == null
                          ? const Text(
                              '',
                              style: TextStyle(
                                fontSize: 36,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                        )
                    ),
            ),
            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Submit Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
