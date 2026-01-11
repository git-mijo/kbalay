import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_hoa/features/chats/page.dart';
import 'package:intl/intl.dart';

class ChatMessageList extends StatelessWidget {
  final Stream<QuerySnapshot>? messagesStream;
  final String? currentUserId;
  final String? helperName;
  final String? helperId;
  final String? chatId;
  final String? requestId;

  const ChatMessageList({
    super.key,
    required this.messagesStream,
    required this.currentUserId,
    required this.helperName,
    required this.helperId,
    required this.chatId,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    if (messagesStream == null) {
      // If no stream is provided, show empty
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: messagesStream,
      builder: (context, msgSnapshot) {
        final messages = msgSnapshot.data?.docs;
        if (messages == null || messages.isEmpty) {
          return const SizedBox.shrink();
        }

        // Safely get last message data
        final lastMessageData = messages.last.data() as Map<String, dynamic>? ?? {};
        final lastMessageContent = (lastMessageData['content'] as String?) ?? '';
        final timestamp = lastMessageData['timestamp'] != null
            ? (lastMessageData['timestamp'] as Timestamp).toDate()
            : null;
        final formattedTime = timestamp != null
            ? DateFormat('hh:mm a').format(timestamp)
            : '';

        // Ensure helperName is never null or empty
        final displayName = (helperName?.isNotEmpty == true) ? helperName! : 'Helper';
        final safeChatId = chatId ?? '';
        final safeRequestId = requestId ?? '';
        final safeHelperId = helperId ?? '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InkWell(
            onTap: () {
              if (safeChatId.isEmpty || safeRequestId.isEmpty || safeHelperId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat data is incomplete')),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    chatId: safeChatId,
                    requestId: safeRequestId,
                    requesterId: safeHelperId,
                  ),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                // Name and last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastMessageContent,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Timestamp
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
