import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestOfferCard extends StatelessWidget {
  final String userId;
  final String status;
  final Timestamp timestamp;
  final VoidCallback onApprove;
  final VoidCallback onDeny;
  

  const RequestOfferCard({
    super.key,
    required this.userId,
    required this.timestamp,
    required this.status,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection("master_residents")
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("User data not found"),
          );
        }

        final userDoc = snapshot.data!.docs.first;
        final user = userDoc.data() as Map<String, dynamic>;
        final String? base64String = user['profileImageBase64'] as String?;
        final Uint8List? userImage = base64String != null && base64String.isNotEmpty
            ? base64Decode(base64String)
            : null;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.lightBlueAccent,
                  backgroundImage: userImage != null
                      ? MemoryImage(userImage)
                      : null,
                  child: userImage == null
                    ? Text(
                      user['firstName'].isNotEmpty ? user['firstName'][0].toUpperCase() : "U",
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    )
                  : null,
                ),

                const SizedBox(width: 14),

                // USER INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${user["firstName"] ?? ""} ${user["lastName"] ?? ""}".trim(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Offered on: ${formatDate(timestamp)}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // ACTION BUTTONS
                if(status == 'pending')
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(90, 36),
                        ),
                        child: const Text("Approve"),
                      ),
                      const SizedBox(height: 6),
                      ElevatedButton(
                        onPressed: onDeny,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(90, 36),
                        ),
                        child: const Text("Deny"),
                      )
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: status == 'Approved' ? Colors.green.shade600 :Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

              ],
            ),
          ),
        );
      },
    );
  }

  String formatDate(Timestamp timestamp) {
    final dt = timestamp.toDate();
    return "${dt.month}/${dt.day}/${dt.year}  "
        "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
