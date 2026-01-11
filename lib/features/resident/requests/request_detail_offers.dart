import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/resident/requests/request_offer_card.dart';

class RequestDetailOffers extends StatelessWidget {
  final String requestId;

  const RequestDetailOffers({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("requests")
            .doc(requestId)
            .collection("offers")
            .orderBy("timestamp", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No offers yet.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final offers = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index].data() as Map<String, dynamic>;
              final offerId = offers[index].id;
              return RequestOfferCard(
                userId: offer["offerUserId"],
                timestamp: offer["timestamp"],
                status: offer["offerStatus"],
                onApprove: () => approveOffer(requestId, offerId, offer["offerUserId"]),
                onDeny: () => denyOffer(requestId, offerId, offer["offerUserId"]),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> approveOffer(String requestId, String offerId, String offerUserId) async {
    final db = FirebaseFirestore.instance;

    // 1️⃣ Update offer status to Approved
    await db
        .collection("requests")
        .doc(requestId)
        .collection("offers")
        .doc(offerId)
        .update({"offerStatus": "Approved"});

    // 2️⃣ Count all approved offers for this request
    final approvedOffersQuery = await db
        .collection("requests")
        .doc(requestId)
        .collection("offers")
        .where("offerStatus", isEqualTo: "Approved")
        .get();

    final approvedCount = approvedOffersQuery.docs.length;

    // 3️⃣ Update helpersAccepted in the request document
    await db.collection("requests").doc(requestId).update({
      "helpersAccepted": approvedCount,
    });

    // 4️⃣ Add system message in chat
    final query = await db
        .collection('chats')
        .where('relatedRequestId', isEqualTo: requestId)
        .where('participants', arrayContains: offerUserId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final chatId = query.docs.first.id;
      final systemMessage = "🎉 Offer has been approved!";
      await db.collection('chats').doc(chatId).collection('messages').add({
        'content': systemMessage,
        'senderId': 'system',
        'timestamp': FieldValue.serverTimestamp(),
        'mediaUrl': null,
        'isSystemMessage': true,
      });
      await db.collection('chats').doc(chatId).update({
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }


  Future<void> denyOffer(String requestId, String offerId, String offerUserId) async {
    final db = FirebaseFirestore.instance;

    await FirebaseFirestore.instance
        .collection("requests")
        .doc(requestId)
        .collection("offers")
        .doc(offerId)
        .update({"offerStatus": "Denied"});

        final approvedOffersQuery = await db
        .collection("requests")
        .doc(requestId)
        .collection("offers")
        .where("offerStatus", isEqualTo: "Approved")
        .get();

    final approvedCount = approvedOffersQuery.docs.length;

    // 3️⃣ Update helpersAccepted in the request document
    await db.collection("requests").doc(requestId).update({
      "helpersAccepted": approvedCount,
    });

    // 4️⃣ Add system message in chat
    final query = await db
        .collection('chats')
        .where('relatedRequestId', isEqualTo: requestId)
        .where('participants', arrayContains: offerUserId)
        .limit(1)
        .get();      

    if (query.docs.isNotEmpty) {
      final chatId = query.docs.first.id;
      final systemMessage = "❌ Offer has been denied.";
      await FirebaseFirestore.instance.collection('chats').doc(chatId).collection('messages').add({
        'content': systemMessage,
        'senderId': 'system',
        'timestamp': FieldValue.serverTimestamp(),
        'mediaUrl': null,
        'isSystemMessage': true,
      });
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }
}
