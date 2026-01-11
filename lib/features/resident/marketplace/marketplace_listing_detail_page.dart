import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_hoa/features/resident/marketplace/marketplace_offers_page.dart';
import './create_listing_page.dart';
import './marketplace_detail_image_carousel.dart';
import './marketplace_chat_page.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/profile_page.dart';

class MarketplaceListingDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const MarketplaceListingDetailPage({super.key, required this.data});

  @override
  State<MarketplaceListingDetailPage> createState() =>
      _MarketplaceListingDetailPageState();
}

class _MarketplaceListingDetailPageState
    extends State<MarketplaceListingDetailPage> {
  late Map<String, dynamic> data;
  bool _loadingOffer = false;
  bool _cancelLoading = false;
  @override
  void initState() {
    super.initState();
    data = Map<String, dynamic>.from(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images =
        (data['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [];
    final status = data['status'];
    final isOverlay = status == 'SOLD' || status == 'WITHDRAWN';
    final user = FirebaseAuth.instance.currentUser;
    final currentUserId = user?.uid;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: const Color(0xFF155DFD),
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Item Details'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
            MarketplaceDetailImageCarousel(images: images),

            const SizedBox(height: 16),

            // Title + action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listing title
                  Expanded(
                    child: Text(
                      data['title'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // SELLER: Offers button (only if owner & offers exist)
                  if (currentUserId != null &&
                      data['sellerId'] == currentUserId)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('marketplace_offers')
                          .where('listingId', isEqualTo: data['listingId'])
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox();
                        }

                        final offerCount = snapshot.data!.docs.length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF155DFD),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              elevation: 0,
                            ),
                            onPressed: () async {
                              final updatedData = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MarketplaceOffersPage(
                                    listingId: data['listingId'],
                                    listingTitle: data['title'],
                                  ),
                                ),
                              );

                              if (updatedData != null &&
                                  updatedData is Map<String, dynamic>) {
                                setState(() {
                                  data = {...data, ...updatedData};
                                });
                              }
                            },
                            child: Text('Offers ($offerCount)'),
                          ),
                        );
                      },
                    ),

                  // Owner actions
                  if (currentUserId != null &&
                      data['sellerId'] == currentUserId)
                    data['status'] != 'SOLD'
                        // Edit button for non-sold items
                        ? OutlinedButton.icon(
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blueGrey,
                              side: const BorderSide(color: Colors.blueGrey),
                            ),
                            onPressed: () async {
                              final updatedData = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateListingPage(
                                    listingId: data['listingId'],
                                    initialData: data,
                                  ),
                                ),
                              );

                              if (updatedData != null &&
                                  updatedData is Map<String, dynamic>) {
                                setState(() {
                                  data = updatedData;
                                });
                              }
                            },
                          )
                        // Withdraw button for SOLD items
                        : OutlinedButton.icon(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                            ),
                            label: const Text('Withdraw'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                            onPressed: _cancelLoading
                                ? null
                                : () async {
                                    setState(() => _cancelLoading = true);
                                    final db = FirebaseFirestore.instance;

                                    final listingRef = db
                                        .collection('marketplace_listings')
                                        .doc(data['listingId']);

                                    await listingRef.update({
                                      'buyerId': null,
                                      'soldAt': null,
                                      'status': 'WITHDRAWN',
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    });

                                    final offersQuery = await db
                                        .collection('marketplace_offers')
                                        .where(
                                          'listingId',
                                          isEqualTo: data['listingId'],
                                        )
                                        .get();

                                    for (final doc in offersQuery.docs) {
                                      await doc.reference.update({
                                        'status': 'PENDING',
                                      });
                                    }

                                    if (mounted) {
                                      setState(() {
                                        data['buyerId'] = null;
                                        data['soldAt'] = null;
                                        data['status'] = 'WITHDRAWN';
                                        _cancelLoading = false;
                                      });
                                    }
                                  },
                          ),

                  // BUY (not owner)
                  if (currentUserId != null &&
                      data['sellerId'] != currentUserId)
                    ElevatedButton(
                      onPressed: _loadingOffer
                          ? null
                          : () async {
                              setState(() => _loadingOffer = true);

                              final userId =
                                  FirebaseAuth.instance.currentUser?.uid;
                              final listingId = data['listingId'];
                              final sellerId = data['sellerId'];
                              if (userId == null ||
                                  listingId == null ||
                                  sellerId == null)
                                return;

                              final db = FirebaseFirestore.instance;

                              final offerQuery = await db
                                  .collection('marketplace_offers')
                                  .where('listingId', isEqualTo: listingId)
                                  .where('buyerId', isEqualTo: userId)
                                  .limit(1)
                                  .get();

                              String offerId;
                              if (offerQuery.docs.isNotEmpty) {
                                offerId = offerQuery.docs.first.id;
                              } else {
                                final newOfferRef = db
                                    .collection('marketplace_offers')
                                    .doc();
                                await newOfferRef.set({
                                  'offerId': newOfferRef.id,
                                  'listingId': listingId,
                                  'sellerId': sellerId,
                                  'buyerId': userId,
                                  'status': 'PENDING',
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                                offerId = newOfferRef.id;
                              }

                              final chatQuery = await db
                                  .collection('marketplace_chats')
                                  .where('listingId', isEqualTo: listingId)
                                  .where('participants', arrayContains: userId)
                                  .limit(1)
                                  .get();

                              String chatId;
                              if (chatQuery.docs.isNotEmpty) {
                                chatId = chatQuery.docs.first.id;
                              } else {
                                final newChatRef = await db
                                    .collection('marketplace_chats')
                                    .add({
                                      'listingId': listingId,
                                      'offerId': offerId,
                                      'participants': [userId, sellerId],
                                      'lastMessageTime':
                                          FieldValue.serverTimestamp(),
                                    });
                                chatId = newChatRef.id;
                              }

                              final updatedData = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MarketplaceChatPage(
                                    listingId: data['listingId'],
                                    chatId: chatId,
                                  ),
                                ),
                              );

                              if (updatedData != null &&
                                  updatedData['offerCancelled'] == true) {
                                // remove offer from local state
                                setState(() {
                                  data['buyerId'] = null;
                                  // other updates if needed
                                });
                              }

                              setState(() => _loadingOffer = false);
                            },
                      child: _loadingOffer
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Message Seller'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT: Price
                  Text(
                    '₱${data['price']}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3675FF),
                    ),
                  ),

                  const Spacer(),

                  if (currentUserId != null &&
                      data['sellerId'] != currentUserId &&
                      !(data['status'] == 'SOLD' &&
                          currentUserId == data['buyerId']))
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('marketplace_offers')
                          .where('listingId', isEqualTo: data['listingId'])
                          .where('buyerId', isEqualTo: currentUserId)
                          .limit(1)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const SizedBox();
                        }

                        final offerDoc = snapshot.data!.docs.first;
                        final offerId = offerDoc.id;
                        final buyerId = offerDoc['buyerId'];
                        final listingId = offerDoc['listingId'];

                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _cancelLoading
                                ? null
                                : () async {
                                    setState(() => _cancelLoading = true);
                                    final db = FirebaseFirestore.instance;

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

                                    if (chatQuery.docs.isNotEmpty) {
                                      await chatQuery.docs.first.reference
                                          .delete();
                                    }

                                    await db
                                        .collection('marketplace_offers')
                                        .doc(offerId)
                                        .delete();

                                    if (mounted)
                                      setState(() => _cancelLoading = false);
                                  },
                            child: _cancelLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Cancel Offer',
                                    style: TextStyle(fontSize: 14),
                                  ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(data['description'] ?? 'No description provided.'),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (data['status'] != 'ACTIVE')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: data['status'] == 'SOLD'
                            ? Colors.red[400]
                            : Colors.orange[400],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        data['status'] == 'SOLD' && data['soldAt'] != null
                            ? 'SOLD • ${_formatDate(data['soldAt'])}'
                            : data['status'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (data['sellerId'] != currentUserId) ...[
              // Seller label
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Seller',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),

              // Seller card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        data['sellerProfileImage'] != null &&
                            data['sellerProfileImage'].isNotEmpty
                        ? MemoryImage(base64Decode(data['sellerProfileImage']))
                        : const NetworkImage(
                                'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                              )
                              as ImageProvider,
                  ),
                  title: Text(data['sellerName']),
                  subtitle: const Text('View Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfilePage(userId: data['sellerId']),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatDate(Timestamp ts) {
  final d = ts.toDate();
  return '${d.month}/${d.day}/${d.year}';
}
