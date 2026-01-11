import 'package:flutter/material.dart';
import './marketplace_listing_detail_page.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './marketplace_offers_page.dart';

class MarketplaceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMyPurchases;
  const MarketplaceCard({
    super.key,
    required this.data,
    this.isMyPurchases = false,
  });

  @override
  Widget build(BuildContext context) {
    final photos = data['photos'] as List?;
    final String? base64Image = (photos != null && photos.isNotEmpty)
        ? photos.first
        : null;

    final status = data['status'];
    final isOverlay = status == 'SOLD' || status == 'WITHDRAWN';

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isSeller = currentUserId != null && data['sellerId'] == currentUserId;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MarketplaceListingDetailPage(data: data),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        color: Colors.white,
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                base64Image != null
                    ? Image.memory(
                        base64Decode(base64Image),
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'images/no-image-item.png',
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),

                if (isOverlay && !isMyPurchases)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Category badge top-right
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 221, 233, 255),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      data['categoryName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 47, 72, 156),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Title and price below image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        data['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Price + Offers Button Row
                      Row(
                        children: [
                          // Price on left
                          Text(
                            '₱${data['price']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color.fromARGB(255, 54, 117, 255),
                            ),
                          ),

                          const Spacer(),

                          if (isSeller)
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('marketplace_offers')
                                  .where(
                                    'listingId',
                                    isEqualTo: data['listingId'],
                                  )
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData ||
                                    snapshot.data!.docs.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final offerCount = snapshot.data!.docs.length;
                                return ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MarketplaceOffersPage(
                                          listingId: data['listingId'],
                                          listingTitle: data['title'],
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                    minimumSize: const Size(0, 30),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  child: Text(
                                    'Offers ($offerCount)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
