import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResidentService {
  final _db = FirebaseFirestore.instance;
  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    final snapshot = await _db
        .collection('announcements')
        .orderBy('timePosted', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'isCritical': data['isCritical'] ?? false,
        'timePosted': data['timePosted'] ?? null,
      };
    }).toList();
  }
  
}
