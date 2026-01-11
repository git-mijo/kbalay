import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ResidentAnnouncementsFeed extends StatelessWidget {
  const ResidentAnnouncementsFeed({super.key});

  String formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    return DateFormat('MMM d, yyyy – hh:mm a').format(date); 
    // Example: Jan 8, 2026 – 09:30 AM
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcements"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('announcements')
            .orderBy('timePosted', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No announcements found"),
            );
          }

          final announcements = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': data['announcementId'] ?? doc.id,
              'title': data['title'] ?? '',
              'description': data['description'] ?? '',
              'isCritical': data['isCritical'] ?? false,
              'timePosted': data['timePosted'],
            };
          }).toList();

          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final item = announcements[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(item['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (item['timePosted'] != null)
                        Text(
                          formatTimestamp(item['timePosted']),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  trailing: item['isCritical'] == true
                      ? const Icon(Icons.warning, color: Colors.red)
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnnouncementDetailPage(item: item),
                      ),
                    );
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

/// Full-page announcement view
class AnnouncementDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const AnnouncementDetailPage({super.key, required this.item});

  String formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    return DateFormat('MMM d, yyyy – hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Announcement"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['title'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (item['isCritical'] == true)
              Row(
                children: const [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 4),
                  Text(
                    'Critical',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              item['description'],
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            if (item['timePosted'] != null)
              Text(
                "Posted on: ${formatTimestamp(item['timePosted'])}",
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
