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

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

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

    setState(() {});
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final userId = _auth.currentUser?.uid;
    if (text.isEmpty || chatId == null || userId == null) return;

    final messageRef = _db
        .collection('marketplace_chats')
        .doc(chatId)
        .collection('messages');
    await messageRef.add({
      'content': text,
      'senderId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _db.collection('marketplace_chats').doc(chatId).update({
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (chatId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentUserId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
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
                    final isMe = message['senderId'] == currentUserId;
                    final content = message['content'] ?? '';

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
        ],
      ),
    );
  }
}
