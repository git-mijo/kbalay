import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/authentication/services/auth_service.dart';
import 'package:flutter_hoa/features/resident/requests/widget/request_chat_list.dart';

class RequestDetailChats extends StatefulWidget {
  final String requestId;

  const RequestDetailChats({super.key, required this.requestId});

  @override
  State<RequestDetailChats> createState() => _RequestDetailChatsState();
}

class _RequestDetailChatsState extends State<RequestDetailChats> {
  final currentUserId = AuthService().currentUser!.uid;
  Map<String, String> helperNames = {};
  bool _helpersFetched = false;

  @override
  void initState() {
    super.initState();
    _fetchHelperNamesForRequest();
  }

  /// Fetch all helper names for this request
  void _fetchHelperNamesForRequest() async {
    final chatSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('relatedRequestId', isEqualTo: widget.requestId)
        .get();

    final allParticipantIds = <String>{};
    for (var chatDoc in chatSnapshot.docs) {
      final participantsField = chatDoc['participants'];
      if (participantsField != null) {
        final participants = List<String>.from(participantsField);
        allParticipantIds.addAll(participants);
      }
    }

    final idsToFetch = allParticipantIds.where((id) => id != currentUserId).toList();
    if (idsToFetch.isEmpty) {
      if (mounted) setState(() => _helpersFetched = true);
      return;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('master_residents')
        .where('userId', whereIn: idsToFetch)
        .get();

    final Map<String, String> names = {};
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final firstName = data['firstName'] ?? '';
      // final fullName = [firstName, middleName, lastName, suffix].where((s) => s.isNotEmpty).join(' ');
      names[data['userId']] = firstName.isNotEmpty ? firstName : 'Helper';
    }

    if (mounted) {
      setState(() {
        helperNames = names;
        _helpersFetched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wait until helper names are fetched
    if (!_helpersFetched) {
      return const Center(child: CircularProgressIndicator());
    }

    final chatsStream = FirebaseFirestore.instance
        .collection('chats')
        .where('relatedRequestId', isEqualTo: widget.requestId)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: chatsStream,
      builder: (context, chatSnapshot) {
        if (chatSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (chatSnapshot.hasError) {
          return Center(child: Text("Error: ${chatSnapshot.error}"));
        }

        final chatDocs = chatSnapshot.data!.docs;

        if (chatDocs.isEmpty) {
          return const Center(child: Text("No chats yet"));
        }

        chatDocs.sort((a, b) {
          final t1 = a['lastMessageTime'] as Timestamp;
          final t2 = b['lastMessageTime'] as Timestamp;
          return t2.compareTo(t1); // descending
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: chatDocs.map((chatDoc) {
              final chatId = chatDoc.id;
              final participants = chatDoc['participants'] != null
                  ? List<String>.from(chatDoc['participants'])
                  : <String>[];

              // Pick first helper (not current user)
              final helperId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
              final helperName = helperNames[helperId] ?? 'Helper';

              final messagesStream = FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChatMessageList(
                    messagesStream: messagesStream,
                    currentUserId: currentUserId,
                    helperName: helperName,
                    helperId: helperId,
                    chatId: chatId,
                    requestId: widget.requestId,
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
