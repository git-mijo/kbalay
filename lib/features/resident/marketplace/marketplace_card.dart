import 'package:flutter/material.dart';
import './marketplace_listing_detail_page.dart';
import 'dart:convert';

class MarketplaceCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const MarketplaceCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final photos = data['photosBase64'] as List?;
    final String? base64Image = (photos != null && photos.isNotEmpty)
        ? photos.first
        : null;

    final isSold = data['status'] == 'SOLD' || data['status'] == 'WITHDRAWN';

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

                if (isSold)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      alignment: Alignment.center,
                      child: const Text(
                        'SOLD',
                        style: TextStyle(
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
                  // Name / Title on top
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
                  // Price below
                  Text(
                    '₱${data['price']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 54, 117, 255),
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
