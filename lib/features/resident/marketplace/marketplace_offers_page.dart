import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import './marketplace_chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketplaceOffersPage extends StatefulWidget {
  final String listingTitle;
  final String listingId;

  const MarketplaceOffersPage({
    super.key,
    required this.listingId,
    this.listingTitle = '',
  });

  @override
  State<MarketplaceOffersPage> createState() => _MarketplaceOffersPageState();
}

class _MarketplaceOffersPageState extends State<MarketplaceOffersPage> {
  String? _approvingOfferId;

  Future<Map<String, Map<String, String>>> _fetchUsers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('master_residents')
        .get();

    final map = <String, Map<String, String>>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final fullName =
          '${data['firstName'] ?? 'Anonymous'} ${data['lastName'] ?? ''}'
              .trim();
      map[data['userId']] = {
        'name': fullName,
        'profileImageBase64': data['profileImageBase64'] ?? '',
      };
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: const Color(0xFF155DFD),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Offers'),
        ),
      ),
      body: FutureBuilder<Map<String, Map<String, String>>>(
        future: _fetchUsers(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final userMap = userSnapshot.data!;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('marketplace_listings')
                .doc(widget.listingId)
                .snapshots(),
            builder: (context, listingSnapshot) {
              if (!listingSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final listingData =
                  listingSnapshot.data!.data() as Map<String, dynamic>? ?? {};
              final listingStatus = listingData['status'] ?? 'ACTIVE';

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('marketplace_offers')
                    .where('listingId', isEqualTo: widget.listingId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final offers = snapshot.data!.docs;
                  if (offers.isEmpty) {
                    return const Center(child: Text('No offers yet.'));
                  }

                  return Column(
                    children: [
                      // Top bar showing item title
                      Container(
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Text(
                          widget.listingTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Offer list
                      Expanded(
                        child: ListView.builder(
                          itemCount: offers.length,
                          itemBuilder: (context, index) {
                            final offerDoc = offers[index];
                            final offer =
                                offerDoc.data() as Map<String, dynamic>;
                            final offerId = offerDoc.id;
                            final buyerId = offer['buyerId'] ?? '';
                            final buyer = userMap[buyerId];
                            final buyerName = buyer?['name'] ?? 'Anonymous';
                            final profileImage = buyer?['profileImageBase64'];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Row(
                                  children: [
                                    // Buyer Avatar
                                    CircleAvatar(
                                      backgroundImage:
                                          (profileImage != null &&
                                              profileImage.isNotEmpty)
                                          ? MemoryImage(
                                              base64Decode(profileImage),
                                            )
                                          : const NetworkImage(
                                                  'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                                                )
                                                as ImageProvider,
                                    ),
                                    const SizedBox(width: 12),

                                    // Buyer Name + Status
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            buyerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if ((offer['status'] ?? '') ==
                                              'APPROVED') ...[
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Accepted Buyer',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Buttons: Approve (only if listing active) / Open Chat
                                    Row(
                                      children: [
                                        if (listingStatus == "ACTIVE" &&
                                            offer['status'] == "PENDING")
                                          TextButton(
                                            onPressed:
                                                listingStatus != 'ACTIVE' ||
                                                    _approvingOfferId != null
                                                ? null
                                                : () async {
                                                    setState(
                                                      () => _approvingOfferId =
                                                          offerId,
                                                    );

                                                    final db = FirebaseFirestore
                                                        .instance;
                                                    final listingRef = db
                                                        .collection(
                                                          'marketplace_listings',
                                                        )
                                                        .doc(widget.listingId);
                                                    final offerRef = db
                                                        .collection(
                                                          'marketplace_offers',
                                                        )
                                                        .doc(offerId);

                                                    try {
                                                      await db.runTransaction((
                                                        transaction,
                                                      ) async {
                                                        final listingSnap =
                                                            await transaction
                                                                .get(
                                                                  listingRef,
                                                                );
                                                        if (!listingSnap.exists)
                                                          throw Exception(
                                                            'Listing not found',
                                                          );
                                                        final listingData =
                                                            listingSnap.data()
                                                                as Map<
                                                                  String,
                                                                  dynamic
                                                                >;
                                                        if (listingData['status'] !=
                                                            'ACTIVE') {
                                                          throw Exception(
                                                            'Listing already sold',
                                                          );
                                                        }

                                                        transaction.update(
                                                          listingRef,
                                                          {
                                                            'status': 'SOLD',
                                                            'buyerId': buyerId,
                                                            'soldAt':
                                                                FieldValue.serverTimestamp(),
                                                          },
                                                        );

                                                        transaction.update(
                                                          offerRef,
                                                          {
                                                            'status':
                                                                'APPROVED',
                                                            'approvedAt':
                                                                FieldValue.serverTimestamp(),
                                                          },
                                                        );
                                                      });

                                                      final updatedListing = {
                                                        'status': 'SOLD',
                                                        'buyerId': buyerId,
                                                        'soldAt':
                                                            Timestamp.now(),
                                                      };
                                                      Navigator.pop(
                                                        context,
                                                        updatedListing,
                                                      );
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            e.toString(),
                                                          ),
                                                        ),
                                                      );
                                                    } finally {
                                                      if (mounted)
                                                        setState(
                                                          () =>
                                                              _approvingOfferId =
                                                                  null,
                                                        );
                                                    }
                                                  },
                                            child: _approvingOfferId == offerId
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Text(
                                                    'Approve',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                          ),

                                        const SizedBox(width: 6),
                                        TextButton(
                                          onPressed: () async {
                                            final db =
                                                FirebaseFirestore.instance;
                                            final sellerId = FirebaseAuth
                                                .instance
                                                .currentUser
                                                ?.uid;
                                            final offerDoc =
                                                offers[index].data()
                                                    as Map<String, dynamic>;
                                            final buyerId = offerDoc['buyerId'];
                                            final listingId =
                                                offerDoc['listingId'];
                                            final offerId = offerDoc['offerId'];

                                            if (sellerId == null ||
                                                buyerId == null ||
                                                listingId == null)
                                              return;

                                            final chatQuery = await db
                                                .collection('marketplace_chats')
                                                .where(
                                                  'listingId',
                                                  isEqualTo: listingId,
                                                )
                                                .where(
                                                  'participants',
                                                  arrayContains: buyerId,
                                                )
                                                .limit(1)
                                                .get();

                                            String chatId;
                                            if (chatQuery.docs.isNotEmpty) {
                                              chatId = chatQuery.docs.first.id;
                                            } else {
                                              final newChatRef = await db
                                                  .collection(
                                                    'marketplace_chats',
                                                  )
                                                  .add({
                                                    'listingId': listingId,
                                                    'offerId': offerId,
                                                    'participants': [
                                                      sellerId,
                                                      buyerId,
                                                    ],
                                                    'lastMessageTime':
                                                        FieldValue.serverTimestamp(),
                                                  });
                                              chatId = newChatRef.id;
                                            }

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    MarketplaceChatPage(
                                                      listingId: listingId,
                                                      chatId: chatId,
                                                    ),
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue.shade50,
                                            foregroundColor:
                                                Colors.blue.shade800,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 15,
                                            ),
                                            minimumSize: const Size(0, 0),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Open Chat',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
