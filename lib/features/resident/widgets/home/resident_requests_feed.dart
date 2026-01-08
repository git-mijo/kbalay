import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'post_card.dart';

class ResidentRequestsFeed extends StatelessWidget {
  const ResidentRequestsFeed({super.key});

  Future<Map<String, String>> _fetchRequestTypes() async {
    // Fetch all request types once
    final snapshot = await FirebaseFirestore.instance.collection('request_type').get();
    final Map<String, String> typeMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      typeMap[data['rid']] = data['name'] ?? 'Unknown';
    }
    return typeMap;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _fetchRequestTypes(),
      builder: (context, typeSnapshot) {
        if (typeSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (typeSnapshot.hasError) {
          return Center(child: Text('Error: ${typeSnapshot.error}'));
        }

        final requestTypeMap = typeSnapshot.data!;

        // Stream of requests
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('requests')
              .orderBy('timePosted', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No requests found.'));
            }

            final requests = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final data = requests[index].data() as Map<String, dynamic>;
                final categoryName = requestTypeMap[data['category']] ?? 'Unknown';

                return PostCard(
                  requestId: data['requestId'] ?? '',
                  title: data['title'] ?? '',
                  categoryName: categoryName, // already resolved
                  requesterName: data['requesterId'] ?? 'Anonymous',
                  helpersNeeded: data['helpersNeeded'] ?? 0,
                  helpersAccepted: data['helpersAccepted'] ?? 0,
                  status: data['status'] ?? '',
                  timePosted: (data['timePosted'] as Timestamp?)?.toDate() ?? DateTime.now(),
                  geoPoint: data['geoPoint'],
                );
              },
            );
          },
        );
      },
    );
  }
}
