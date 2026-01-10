import 'package:flutter/material.dart';

class MarketplaceListingDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const MarketplaceListingDetailPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final images = data['photosRef'] as List;
    final isSold = data['status'] == 'SOLD' || data['status'] == 'WITHDRAWN';
    final currentUserId = 'xFjiZSViGdNzmzqsgU3oSuYWdBq2';
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: const Color(0xFF155DFD),
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        automaticallyImplyLeading: true, // back button
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Item Details', style: TextStyle(color: Colors.white)),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Swipable images
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: PageView.builder(
                itemCount: images.isNotEmpty ? images.length : 1,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Image.network(
                        images.isNotEmpty
                            ? images[index]
                            : 'https://t4.ftcdn.net/jpg/06/57/37/01/360_F_657370150_pdNeG5pjI976ZasVbKN9VqH1rfoykdYU.jpg',
                        width: double.infinity,
                        height: double.infinity,
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
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Title + Buy Now button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      data['title'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  if (data['sellerId'] != currentUserId) ...[
                    const SizedBox(width: 12),

                    ElevatedButton(
                      onPressed: () {
                        // placeholder action
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Buy Now Clicked')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF155DFD),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
                  color: Color.fromARGB(255, 54, 117, 255),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Description label
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),

            // Description content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                data['description'] ?? 'No description provided.',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
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
                    // TODO: replace with real seller avatar
                    backgroundImage: const NetworkImage(
                      'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                    ),
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
          ],
        ),
      ),
    );
  }
}
