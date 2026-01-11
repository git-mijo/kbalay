import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/authentication/services/auth_service.dart';
import 'package:flutter_hoa/features/resident/requests/request_card.dart';

class MyRequestsFeedCompleted extends StatelessWidget {
  const MyRequestsFeedCompleted({super.key});
  
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

  // Fetch all users once
  Future<Map<String, String>> _fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('master_residents').get();
    final Map<String, String> userMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      userMap[data['userId']] = data['firstName'] ?? 'Anonymous';
    }
    return userMap;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: Future.wait([
        _fetchRequestTypes(),
        _fetchUsers(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final requestTypeMap = snapshot.data![0];
        final userMap = snapshot.data![1];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
            .collection('requests')
            .orderBy('timePosted', descending: true)
            .snapshots(),
          builder: (context, requestSnapshot) {
            if (requestSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!requestSnapshot.hasData || requestSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No requests found.'));
            }

            final requests = requestSnapshot.data!.docs;
            final user = AuthService().currentUser;
            final currentUserId = user!.uid;

            final filteredRequests = requests.where((r) {
              final data = r.data() as Map<String, dynamic>;
              return data['requesterId'] == currentUserId && data['status'] == 'Completed';
            }).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final data = filteredRequests[index].data() as Map<String, dynamic>;
                final categoryName = requestTypeMap[data['category']] ?? "Unknown";
                final requesterName = userMap[data['requesterId']] ?? "Anonymous";

                return PostCard(
                  requestId: data['requestId'],
                  title: data['title'],
                  categoryName: categoryName,
                  requesterName: requesterName,
                  helpersNeeded: data['helpersNeeded'],
                  helpersAccepted: data['helpersAccepted'],
                  status: data['status'],
                  timePosted: (data['timePosted'] as Timestamp).toDate(),
                  geoPoint: data['geoPoint'],
                  isMyRequest: data['requesterId'] == user!.uid ? true : false,
                );
              },
            );
          },
        );
      },
    );


  }
}
