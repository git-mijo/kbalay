import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  final String requestId;
  final String requesterId;

  const ChatPage({
    super.key,
    required this.requestId,
    required this.requesterId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? chatId; // Store chat document ID

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    final userId = _auth.currentUser!.uid;

    // Check if a chat for this request already exists for these participants
    final query = await _db
        .collection('chats')
        .where('relatedRequestId', isEqualTo: widget.requestId)
        .where('participants', arrayContains: userId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      chatId = query.docs.first.id;
    } else {
      // Create a new chat
      final docRef = await _db.collection('chats').add({
        'relatedRequestId': widget.requestId,
        'participants': [userId, widget.requesterId],
        'lastMessageTime': FieldValue.serverTimestamp(),
        'isGroupChat': false,
      });
      chatId = docRef.id;
    }

    setState(() {}); // Trigger rebuild
  }

  @override
  Widget build(BuildContext context) {
    if (chatId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data()! as Map<String, dynamic>;
                    final isMe = message['senderId'] == _auth.currentUser!.uid;

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message['content'] ?? '',
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
          // Input field
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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || chatId == null) return;

    final userId = _auth.currentUser!.uid;

    final messageRef = _db.collection('chats').doc(chatId).collection('messages');

    await messageRef.add({
      'content': text, // <-- Updated field name
      'senderId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'mediaUrl': null,
    });

    // Update last message timestamp in the chat document
    await _db.collection('chats').doc(chatId).update({
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }
}
