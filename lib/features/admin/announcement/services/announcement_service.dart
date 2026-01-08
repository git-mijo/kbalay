import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnnouncementService {
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

  Future<void> createAnnouncement(Map<String, dynamic> data) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '0';
    final docRef = await _db.collection('announcements').add({
      ...data,
      'userId': uid,
      'timePosted': FieldValue.serverTimestamp(),
    });
    await docRef.update({'announcementId': docRef.id});
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> data) async {
    await _db.collection('announcements').doc(id).update(data);
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
  }
}
