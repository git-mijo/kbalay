import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './create_listing_page.dart';
import './marketplace_detail_image_carousel.dart';
import 'dart:convert';

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

                  // EDIT (owner)
                  if (currentUserId != null &&
                      data['sellerId'] == currentUserId)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
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
                    ),

                  // BUY (not owner)
                  if (currentUserId != null &&
                      data['sellerId'] != currentUserId)
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Buy Now Clicked')),
                        );
                      },
                      child: const Text('Buy Now'),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Price
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '₱${data['price']}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3675FF),
                ),
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
                              as ImageProvider, // fallback if no image
                  ),
                  title: Text(data['sellerName']),
                  subtitle: const Text('View Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Navigate to seller profile
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (data['status'] !=
                      'ACTIVE') // only show for SOLD/WITHDRAWN
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
                        data['status'],
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
          ],
        ),
      ),
    );
  }
}
