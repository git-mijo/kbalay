import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/authentication/services/auth_service.dart';

class ChatPage extends StatefulWidget {
  final String requestId;
  final String requesterId;
  final String chatId; // optional existing chatId

  const ChatPage({
    super.key,
    required this.requestId,
    required this.requesterId,
    this.chatId = '',
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? chatId;
  Map<String, dynamic>? requestData;
  Map<String, dynamic>? otherData;
  bool _offerSent = false;
  bool _loadingOfferStatus = true;
  bool _otherOfferSent = false;
  bool _loadingOtherOffer = true;

  @override
  void initState() {
    super.initState();
    _initChat();
    _checkIfOfferSent();
  }

  Future<void> _checkOtherOffer() async {
    final otherUserId = otherData?['userId'];
    if (otherUserId == null || widget.requestId.isEmpty) return;

    final doc = await _db
        .collection('requests')
        .doc(widget.requestId)
        .collection('offers')
        .where('offerUserId', isEqualTo: otherUserId)
        .limit(1)
        .get();

    setState(() {
      _otherOfferSent = doc.docs.isNotEmpty;
      _loadingOtherOffer = false;
    });
  }

  Future<void> _initChat() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    String? otherId;

    final doc = await _db.collection('requests').doc(widget.requestId).get();
    if (!doc.exists) return;

    requestData = doc.data();

    // Use chatId if already provided
    if (widget.chatId.isNotEmpty) {
      chatId = widget.chatId;
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      if (chatDoc.exists) {
        final participants = chatDoc['participants'] != null
            ? List<String>.from(chatDoc['participants'])
            : <String>[];
        otherId = participants.firstWhere((id) => id != userId, orElse: () => '');
      }
    } else {
      // Check if a chat exists
      final query = await _db
          .collection('chats')
          .where('relatedRequestId', isEqualTo: widget.requestId)
          .where('participants', arrayContains: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        chatId = query.docs.first.id;
        final chatDoc = await _db.collection('chats').doc(chatId).get();
        if (chatDoc.exists) {
          final participants = chatDoc['participants'] != null
              ? List<String>.from(chatDoc['participants'])
              : <String>[];
          otherId = participants.firstWhere((id) => id != userId, orElse: () => '');
        }
      } else {
        // Create a new chat
        final docRef = await _db.collection('chats').add({
          'relatedRequestId': widget.requestId,
          'participants': [userId, widget.requesterId],
          'lastMessageTime': FieldValue.serverTimestamp(),
          'isGroupChat': false,
        });
        chatId = docRef.id;
        otherId = widget.requesterId;
      }
    }

    // Load other user info safely
    if (otherId != null && otherId.isNotEmpty) {
      final snapshot = await _db
          .collection('master_residents')
          .where('userId', isEqualTo: otherId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        otherData = snapshot.docs.first.data();
        await _checkOtherOffer();
      }
    }

    setState(() {});
  }

  Future<void> _checkIfOfferSent() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final doc = await _db
        .collection('requests')
        .doc(widget.requestId)
        .collection('offers')
        .where('offerUserId', isEqualTo: userId)
        .limit(1)
        .get();

    setState(() {
      _offerSent = doc.docs.isNotEmpty;
      _loadingOfferStatus = false;
    });
  }

  Future<void> _offerHelp() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || widget.requestId.isEmpty || chatId == null) return;

    final offersRef = _db
        .collection('requests')
        .doc(widget.requestId)
        .collection('offers');

    final existingQuery =
        await offersRef.where('offerUserId', isEqualTo: userId).limit(1).get();

    bool isNewOffer = false;
    bool isCanceledOffer = false;

    if (existingQuery.docs.isNotEmpty) {
      await offersRef.doc(existingQuery.docs.first.id).delete();
      isCanceledOffer = true;
      setState(() => _offerSent = false);
    } else {
      final newDoc = offersRef.doc();
      await newDoc.set({
        'offerId': newDoc.id,
        'offerStatus': 'pending',
        'offerUserId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      isNewOffer = true;
      setState(() => _offerSent = true);
    }

    // Add system message
    final systemMessage = isNewOffer
        ? "💡 Help offer sent."
        : isCanceledOffer
            ? "❌ Help offer was cancelled."
            : "⏰ Help offer updated.";

    if (chatId != null) {
      await _db.collection('chats').doc(chatId).collection('messages').add({
        'content': systemMessage,
        'senderId': 'system',
        'timestamp': FieldValue.serverTimestamp(),
        'mediaUrl': null,
        'isSystemMessage': true,
      });

      await _db.collection('chats').doc(chatId).update({
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isNewOffer
              ? "Offer sent!"
              : isCanceledOffer
                  ? "Offer cancelled!"
                  : "Offer updated!",
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final userId = _auth.currentUser?.uid;
    if (text.isEmpty || chatId == null || userId == null) return;

    final messageRef = _db.collection('chats').doc(chatId).collection('messages');
    await messageRef.add({
      'content': text,
      'senderId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'mediaUrl': null,
    });

    await _db.collection('chats').doc(chatId).update({
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (chatId == null || requestData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          // Offer / Request Info
          if (requestData!['requesterId'] != currentUserId)
            _buildOfferRow()
          else
            _buildRequesterRow(),

          // Messages
          Expanded(
            child: chatId == null
                ? const SizedBox.shrink()
                : StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('chats')
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
                          final isMe = message['senderId'] == currentUserId;
                          final isSystem = message['senderId'] == 'system';
                          final content = message['content'] ?? '';

                          return Align(
                            alignment: isSystem
                                ? Alignment.center
                                : (isMe ? Alignment.centerRight : Alignment.centerLeft),
                            child: Container(
                              constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.7),
                              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSystem
                                    ? Colors.amber.shade200
                                    : (isMe ? Colors.blueAccent : Colors.grey.shade300),
                                borderRadius: isSystem
                                    ? BorderRadius.circular(20)
                                    : BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: isMe
                                            ? const Radius.circular(16)
                                            : const Radius.circular(0),
                                        bottomRight: isMe
                                            ? const Radius.circular(0)
                                            : const Radius.circular(16),
                                      ),
                                border: isSystem
                                    ? Border.all(color: Colors.orange.shade700, width: 1.2)
                                    : null,
                              ),
                              child: Text(
                                content,
                                textAlign: isSystem ? TextAlign.center : TextAlign.left,
                                style: TextStyle(
                                  color: isSystem
                                      ? Colors.black87
                                      : (isMe ? Colors.white : Colors.black87),
                                  fontStyle: isSystem ? FontStyle.italic : FontStyle.normal,
                                  fontWeight:
                                      isSystem ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          // Input
          if(requestData?['status'] != 'Completed')
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "Type your message...",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _buildOfferRow() {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // CircleAvatar(
          //   radius: 24,
          //   backgroundColor: Colors.blueAccent,
          //   child: const Text(
          //     'A',
          //     style: TextStyle(fontSize: 20, color: Colors.white),
          //   ),
          // ),
          // const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requestData?['title'] ?? 'Request',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Posted by:',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          _loadingOfferStatus
              ? const SizedBox(
                  height: 36,
                  width: 36,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : ElevatedButton(
                  onPressed: _offerHelp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _offerSent ? Colors.redAccent : Colors.blueAccent,
                  ),
                  child: Text(_offerSent ? "Cancel offer" : "Offer help"),
                ),
        ],
      ),
    );
  }

  Widget _buildRequesterRow() {
    final name =
        '${otherData?['firstName'] ?? ''} ${otherData?['lastName'] ?? ''}'.trim();
        

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // CircleAvatar(
          //   radius: 24,
          //   backgroundColor: Colors.blueAccent,
          //   child: const Text(
          //     'B',
          //     style: TextStyle(fontSize: 20, color: Colors.white),
          //   ),
          // ),
          // const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('Request: ${requestData?['title'] ?? ''}',
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          if(requestData?['status'] != 'Completed')
            if (_loadingOtherOffer)
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (!_otherOfferSent)
              ElevatedButton(
                onPressed: () {
                  print("Request help pressed");
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                child: const Text("Request Help"),
              ),
        ],
      ),
    );
  }

}
