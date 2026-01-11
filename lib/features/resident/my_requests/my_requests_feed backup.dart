import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../requests/request_card.dart';
import 'widgets/create_request_page.dart';

class MyRequestsFeed extends StatefulWidget {
  const MyRequestsFeed({super.key});

  @override
  State<MyRequestsFeed> createState() => _MyRequestsFeedState();
}

class _MyRequestsFeedState extends State<MyRequestsFeed> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _loading = true;

  Map<String, String> requestTypeMap = {};
  Map<String, String> userMap = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadUserData();
    await _loadRequestTypes();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _db
        .collection('master_residents')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _userData = snapshot.docs.first.data();
      });
    }

    setState(() => _loading = false);
  }

  Future<void> _loadRequestTypes() async {
    final snapshot = await _db.collection('request_type').get();
    final Map<String, String> map = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      map[data['rid']] = data['name'] ?? 'Unknown';
    }
    setState(() => requestTypeMap = map);
  }

  void _goToCreateRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateRequestPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userId = _userData!['userId'];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreateRequest,
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add),
        label: const Text("Create New Request"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('requests')
            .where('requesterId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No requests found.'));
          }

          // Convert snapshots to list of maps with safe defaults
          final requests = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // fallback timestamp
            final timePosted = (data['timePosted'] as Timestamp?)?.toDate() ?? DateTime.now();

            return {
              ...data,
              'timePosted': timePosted,
            };
          }).toList();

          // sort locally descending by timePosted
          requests.sort((a, b) => (b['timePosted'] as DateTime).compareTo(a['timePosted'] as DateTime));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index];

              final categoryName = requestTypeMap[data['category']] ?? "Unknown";
              final requesterName = "${data['firstName'] ?? ''} ${data['lastName'] ?? ''}".trim();

              final helpersNeeded = data['helpersNeeded'] ?? 0;
              final helpersAccepted = data['helpersAccepted'] ?? 0;
              final geoPoint = data['geoPoint'] ?? const GeoPoint(0, 0);

              final timePosted = data['timePosted'] as DateTime;

              return PostCard(
                requestId: data['requestId'] ?? '',
                title: data['title'] ?? '',
                categoryName: categoryName,
                requesterName: requesterName,
                helpersNeeded: helpersNeeded,
                helpersAccepted: helpersAccepted,
                status: data['status'] ?? '',
                timePosted: timePosted,
                geoPoint: geoPoint,
                isMyRequest: true,
              );
            },
          );
        },
      ),
    );
  }

}
