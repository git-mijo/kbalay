import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MarketplaceChatPage extends StatefulWidget {
  final String listingId;
  final String chatId; // optional existing chatId

  const MarketplaceChatPage({
    super.key,
    required this.listingId,
    this.chatId = '',
  });

  @override
  State<MarketplaceChatPage> createState() => _MarketplaceChatPageState();
}

class _MarketplaceChatPageState extends State<MarketplaceChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? chatId;
  Map<String, dynamic>? listingData;

  Stream<QuerySnapshot<Map<String, dynamic>>> get offersStream {
    return _db
        .collection('marketplace_offers')
        .where('listingId', isEqualTo: widget.listingId)
        .where('status', isEqualTo: 'PENDING')
        .snapshots();
  }

  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    // 1. Determine chatId
    if (widget.chatId.isNotEmpty) {
      chatId = widget.chatId;
    } else {
      final query = await _db
          .collection('marketplace_chats')
          .where('listingId', isEqualTo: widget.listingId)
          .where('participants', arrayContains: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        chatId = query.docs.first.id;
      } else {
        final docRef = await _db.collection('marketplace_chats').add({
          'listingId': widget.listingId,
          'participants': [userId],
          'lastMessageTime': FieldValue.serverTimestamp(),
        });
        chatId = docRef.id;
      }
    }

    // 2. Fetch initial listing data
    final listingSnap = await _db
        .collection('marketplace_listings')
        .doc(widget.listingId)
        .get();
    if (listingSnap.exists) {
      listingData = listingSnap.data();
    }

    setState(() {});
  }

  Future<void> _sendMessage({String? type, String? content}) async {
    final text = content ?? _controller.text.trim();
    final userId = _auth.currentUser?.uid;
    if (text.isEmpty || chatId == null || userId == null) return;

    await _db
        .collection('marketplace_chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'content': text,
          'senderId': type == "system" ? null : userId,
          'timestamp': FieldValue.serverTimestamp(),
          'type': type ?? 'text',
        });

    await _db.collection('marketplace_chats').doc(chatId).update({
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    if (type != "system") _controller.clear();
  }

  bool get isSeller => _auth.currentUser?.uid == listingData?['sellerId'];
  bool get isBuyer =>
      _auth.currentUser?.uid == listingData?['buyerId'] ||
      _auth.currentUser?.uid != listingData?['sellerId'];

  @override
  Widget build(BuildContext context) {
    if (chatId == null || listingData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(listingData?['title'] ?? "Chat"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('marketplace_chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>? ?? {};
                    final type = message['type'] ?? 'text';
                    final content = message['content'] ?? '';
                    final senderId = message['senderId'];
                    final isMe = senderId == currentUserId;

                    if (type == 'system') {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Center(
                          child: Text(
                            content,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    }

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.blueAccent
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe
                                ? const Radius.circular(16)
                                : const Radius.circular(0),
                            bottomRight: isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          content,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Seller/Buyer action buttons (above message input)
          if (!_actionLoading)
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _db
                  .collection('marketplace_listings')
                  .doc(widget.listingId)
                  .snapshots(),
              builder: (context, listingSnapshot) {
                if (!listingSnapshot.hasData) return const SizedBox.shrink();
                listingData = listingSnapshot.data!.data();

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: offersStream,
                  builder: (context, offersSnapshot) {
                    final offersPending =
                        offersSnapshot.hasData &&
                        offersSnapshot.data!.docs.isNotEmpty;
                    return _buildActionRow(offersPending: offersPending);
                  },
                );
              },
            ),

          // Input row
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type your message...",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow({bool offersPending = false}) {
    final status = listingData?['status'] ?? 'ACTIVE';

    if (isSeller && status == 'ACTIVE' && offersPending) {
      // Seller can accept purchase
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ElevatedButton(
          onPressed: _actionLoading ? null : () => _approveOffer(),
          child: const Text("Accept Purchase"),
        ),
      );
    }

    if (isSeller && status == 'SOLD') {
      // Seller can withdraw sold offer
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: ElevatedButton(
          onPressed: _actionLoading ? null : () => _withdrawOffer(),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text("Withdraw Sale"),
        ),
      );
    }

    if (isBuyer && status == 'ACTIVE' && offersPending) {
      // Buyer can cancel their offer
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: TextButton(
          onPressed: _actionLoading ? null : () => _cancelOffer(),
          style: TextButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red.shade700,
          ),
          child: const Text("Cancel Offer"),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _approveOffer() async {
    setState(() => _actionLoading = true);
    final db = _db;

    // Update listing as SOLD, assign buyerId (example: first offer in chat)
    final offersQuery = await db
        .collection('marketplace_offers')
        .where('listingId', isEqualTo: widget.listingId)
        .where('status', isEqualTo: 'PENDING')
        .limit(1)
        .get();

    if (offersQuery.docs.isEmpty) {
      setState(() => _actionLoading = false);
      return;
    }

    final offerDoc = offersQuery.docs.first;
    final buyerId = offerDoc['buyerId'];

    final listingRef = db
        .collection('marketplace_listings')
        .doc(widget.listingId);
    final offerRef = offerDoc.reference;

    await db.runTransaction((tx) async {
      tx.update(listingRef, {
        'status': 'SOLD',
        'buyerId': buyerId,
        'soldAt': FieldValue.serverTimestamp(),
      });
      tx.update(offerRef, {
        'status': 'APPROVED',
        'approvedAt': FieldValue.serverTimestamp(),
      });
    });

    // Add system message
    await _sendMessage(
      type: 'system',
      content: 'Seller approved the offer. Purchase completed.',
    );

    // Refresh local state
    final listingSnap = await listingRef.get();
    listingData = listingSnap.data();

    setState(() => _actionLoading = false);
  }

  Future<void> _withdrawOffer() async {
    setState(() => _actionLoading = true);
    final db = _db;

    final listingRef = db
        .collection('marketplace_listings')
        .doc(widget.listingId);
    await listingRef.update({
      'status': 'WITHDRAWN',
      'buyerId': null,
      'soldAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update offers back to PENDING
    final offersQuery = await db
        .collection('marketplace_offers')
        .where('listingId', isEqualTo: widget.listingId)
        .get();

    for (final doc in offersQuery.docs) {
      await doc.reference.update({'status': 'PENDING'});
    }

    await _sendMessage(type: 'system', content: 'Seller withdrew the sale.');

    // Refresh local state
    final listingSnap = await listingRef.get();
    listingData = listingSnap.data();

    setState(() => _actionLoading = false);
  }

  Future<void> _cancelOffer() async {
    setState(() => _actionLoading = true);
    final db = _db;
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final offerQuery = await db
        .collection('marketplace_offers')
        .where('listingId', isEqualTo: widget.listingId)
        .where('buyerId', isEqualTo: userId)
        .limit(1)
        .get();

    if (offerQuery.docs.isEmpty) {
      setState(() => _actionLoading = false);
      return;
    }

    final offerDoc = offerQuery.docs.first;

    // Delete offer
    await offerDoc.reference.delete();

    // Delete chat? optional, skipped

    await _sendMessage(type: 'system', content: 'Buyer cancelled the offer.');

    if (mounted) {
      Navigator.pop(context, {'offerCancelled': true});
    }

    setState(() => _actionLoading = false);
  }
}
