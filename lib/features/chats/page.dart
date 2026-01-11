import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/authentication/services/auth_service.dart';

import 'package:flutter_hoa/features/chats/page.dart';

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

  // Offer status of current user
  String? _offerStatus;
  bool _loadingOfferStatus = true;

  // Offer status of other user (on requester side)
  String? _otherOfferStatus;
  bool _loadingOtherOffer = true;

  @override
  void initState() {
    super.initState();
    _initChat();
    _checkOfferStatus();
  }

  /// Check current user offer status
  Future<void> _checkOfferStatus() async {
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
      if (doc.docs.isNotEmpty) {
        _offerStatus = doc.docs.first['offerStatus'] as String?;
      } else {
        _offerStatus = null;
      }
      _loadingOfferStatus = false;
    });
  }

  /// Check other user offer status for requester side button
  Future<void> _checkOtherOfferStatus() async {
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
      if (doc.docs.isNotEmpty) {
        _otherOfferStatus = doc.docs.first['offerStatus'] as String?;
      } else {
        _otherOfferStatus = null;
      }
      _loadingOtherOffer = false;
    });
  }

  /// Initialize chat and load other user info
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
        await _checkOtherOfferStatus();
      }
    }

    setState(() {});
  }

  /// Send / Cancel offer
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
      // Cancel offer
      await offersRef.doc(existingQuery.docs.first.id).delete();
      _offerStatus = null;
      isCanceledOffer = true;
    } else {
      // Send new offer
      final newDoc = offersRef.doc();
      await newDoc.set({
        'offerId': newDoc.id,
        'offerStatus': 'pending',
        'offerUserId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _offerStatus = 'pending';
      isNewOffer = true;
    }

    setState(() {});

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

  Future<void> approveOffer(String requestId, String? offerId, String offerUserId) async {
    final db = FirebaseFirestore.instance;

    // 1️⃣ Ensure we have the offerId
    String? actualOfferId = offerId;

    if (actualOfferId == null || actualOfferId.isEmpty) {
      // Find the offer document by userId
      final query = await db
          .collection("requests")
          .doc(requestId)
          .collection("offers")
          .where("offerUserId", isEqualTo: offerUserId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print("No offer found for user $offerUserId in request $requestId");
        return; // nothing to approve
      }

      actualOfferId = query.docs.first.id;
    }

    // 2️⃣ Update offer status to Approved
    await db
        .collection("requests")
        .doc(requestId)
        .collection("offers")
        .doc(actualOfferId)
        .update({"offerStatus": "Approved"});

    // 3️⃣ Count all approved offers for this request
    final approvedOffersQuery = await db
        .collection("requests")
        .doc(requestId)
        .collection("offers")
        .where("offerStatus", isEqualTo: "Approved")
        .get();

    final approvedCount = approvedOffersQuery.docs.length;

    // 4️⃣ Update helpersAccepted in the request document
    await db.collection("requests").doc(requestId).update({
      "helpersAccepted": approvedCount,
    });

    // 5️⃣ Add system message in chat
    final chatQuery = await db
        .collection('chats')
        .where('relatedRequestId', isEqualTo: requestId)
        .where('participants', arrayContains: offerUserId)
        .limit(1)
        .get();

    if (chatQuery.docs.isNotEmpty) {
      final chatId = chatQuery.docs.first.id;
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

  /// Offer Help Button (for user viewing someone else's request)
  Widget _buildOfferRow() {
    Color buttonColor;
    String buttonText;
    bool buttonEnabled = true;

    switch (_offerStatus) {
      case 'Approved':
        buttonText = 'Offer Approved!';
        buttonEnabled = false;
        buttonColor = Colors.green;
        break;
      case 'Denied':
        buttonColor = Colors.redAccent;
        buttonText = 'Offer Denied';
        buttonEnabled = false;
        break;
      case 'pending':
        buttonColor = Colors.orangeAccent;
        buttonText = 'Cancel Offer';
        break;
      default: // no offer yet
        buttonColor = Colors.blueAccent;
        buttonText = 'Offer Help';
    }

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  requestData?['title'] ?? 'Request',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                // const Text(
                //   'Posted by:',
                //   style: TextStyle(color: Colors.black54),
                // ),
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
                  onPressed: buttonEnabled ? _offerHelp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                  ),
                  child: Text(buttonText),
                ),
        ],
      ),
    );
  }

  /// Requester side: show status of other user's offer
  Widget _buildRequesterRow() {
    final name =
        '${otherData?['firstName'] ?? ''} ${otherData?['lastName'] ?? ''}'.trim();

    Color buttonColor = Colors.blueAccent;
    String buttonText = "Request Help";
    bool buttonEnabled = true;

    switch (_otherOfferStatus) {
      case 'Approved':
        buttonColor = Colors.green;
        buttonText = "Offer Approved!";
        buttonEnabled = false; // already approved, no action
        break;
      case 'Denied':
        buttonColor = Colors.redAccent;
        buttonText = "Offer Denied";
        buttonEnabled = false;
        break;
      case 'pending':
        buttonColor = Colors.orangeAccent;
        buttonText = "Pending Offer";
        buttonEnabled = true; // allow approving
        break;
      default:
        buttonColor = Colors.blueAccent;
        buttonText = "Request Help";
        buttonEnabled = true;
    }

    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
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
          if(buttonText == "Request Help")
            const SizedBox(height: 4,)
          else if(requestData?['status'] != 'Completed')
            _loadingOtherOffer
                ? const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : ElevatedButton(
                    onPressed: buttonEnabled && _otherOfferStatus == 'pending'
                        ? () {
                            approveOffer(
                              widget.requestId,
                              '',
                              otherData?['userId'] ?? '',
                            ).then((_) {
                              // Refresh status after approval
                              _checkOtherOfferStatus();
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                    child: Text(buttonText),
                  ),
        ],
      ),
    );
  }

}
