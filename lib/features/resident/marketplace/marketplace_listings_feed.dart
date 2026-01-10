import 'package:flutter/material.dart';
import './marketplace_card.dart';
import './create_listing_page.dart';

class MarketplaceListingsFeed extends StatelessWidget {
  final bool showCreateButton;

  const MarketplaceListingsFeed({super.key, this.showCreateButton = false});

  // Demo static data
  static final List<Map<String, dynamic>> demoListings = [
    {
      'listingId': '1',
      'sellerId': 'xFjiZSViGdNzmzqsgU3oSuYWdBq2',
      'title': 'iPhone 13 Pro',
      'price': 45000,
      'category': 'electronics',
      'categoryName': 'Electronics & Gadgets',
      'photosRef': [
        'https://static.nike.com/a/images/t_web_pdp_936_v2/f_auto/34604cb1-acc6-4a40-bf26-60185ca7da5c/NIKE+AIR+MAX+1+ESS.png',
      ],
      'description':
          'iPhone 13 Pro in excellent condition, 128GB, no scratches. Comes with original box and charger.',
      'status': 'ACTIVE',
      'timePosted': DateTime.now().subtract(const Duration(hours: 1)),
    },
    {
      'listingId': '2',
      'sellerId': 'otherUser123',
      'title': 'Leather Sofa',
      'price': 12000,
      'category': 'home-goods',
      'categoryName': 'Home Goods & Appliances',
      'photosRef': [
        'https://static.nike.com/a/images/t_web_pdp_936_v2/f_auto/34604cb1-acc6-4a40-bf26-60185ca7da5c/NIKE+AIR+MAX+1+ESS.png',
      ],
      'description':
          'Comfortable 3-seater leather sofa. Minor wear on armrests but still very sturdy.',
      'status': 'ACTIVE',
      'timePosted': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'listingId': '3',
      'sellerId': 'otherUser123',
      'title': 'Nike Sneakers from wo knows where',
      'price': 3500,
      'category': 'fashion',
      'categoryName': 'Clothing & Fashion',
      'photosRef': [
        'https://static.nike.com/a/images/t_web_pdp_535_v2/f_auto/b98d16d8-f75b-4423-aa96-65cd68ac5277/NIKE+COURT+VISION+LO.png',
      ],
      'description':
          'Used Nike sneakers, size 9. Clean and comfortable for daily wear.',
      'status': 'SOLD',
      'timePosted': DateTime.now().subtract(const Duration(days: 2)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final userId = 'xFjiZSViGdNzmzqsgU3oSuYWdBq2';
    final listings = showCreateButton
        ? demoListings.where((l) => l['sellerId'] == userId).toList()
        : demoListings.where((l) => l['sellerId'] != userId).toList();

    listings.sort(
      (a, b) =>
          (b['timePosted'] as DateTime).compareTo(a['timePosted'] as DateTime),
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateListingPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Create Listing"),
        backgroundColor: Colors.blueAccent,
      ),

      body: listings.isEmpty
          ? const Center(child: Text('No listings found.'))
          : Padding(
              padding: EdgeInsets.zero,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 0,
                  childAspectRatio: 1.05,
                ),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  final data = listings[index];
                  return MarketplaceCard(data: data);
                },
              ),
            ),
    );
  }
}
