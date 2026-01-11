import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './marketplace_card.dart';
import './create_listing_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketplaceListingsFeed extends StatefulWidget {
  final bool isMyListings;

  const MarketplaceListingsFeed({super.key, this.isMyListings = false});

  @override
  State<MarketplaceListingsFeed> createState() =>
      _MarketplaceListingsFeedState();
}

class _MarketplaceListingsFeedState extends State<MarketplaceListingsFeed> {
  String? selectedCategoryId; // null = ALL

  Future<Map<String, String>> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('marketplace_categories')
        .where('isActive', isEqualTo: true)
        .get();

    final map = <String, String>{};
    for (var doc in snapshot.docs) {
      map[doc.id] = doc['categoryName'] ?? 'Unknown';
    }
    return map;
  }

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

  Widget _buildCategoryDropdown(Map<String, String> categoryMap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Category',
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: selectedCategoryId,
            isExpanded: true,
            hint: const Text('All categories'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All categories'),
              ),
              ...categoryMap.entries.map((entry) {
                return DropdownMenuItem<String?>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
            ],
            onChanged: (value) {
              setState(() => selectedCategoryId = value);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateListingPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Listing'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_fetchCategories(), _fetchUsers()]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.hasError) {
            return const Center(child: Text('Error loading data'));
          }

          final categoryMap = snapshot.data![0] as Map<String, String>;
          final userMap = snapshot.data![1] as Map<String, Map<String, String>>;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('marketplace_listings')
                .orderBy('timePosted', descending: true)
                .snapshots(),
            builder: (context, listingsSnapshot) {
              if (listingsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!listingsSnapshot.hasData ||
                  listingsSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No listings found.'));
              }

              final listings = listingsSnapshot.data!.docs
                  .map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final sellerInfo = userMap[data['sellerId']] ?? {};

                    return {
                      'listingId': doc.id,
                      'sellerId': data['sellerId'],
                      'sellerName': sellerInfo['name'] ?? 'Anonymous',
                      'sellerProfileImage':
                          sellerInfo['profileImageBase64'] ?? '',
                      'title': data['title'],
                      'price': data['price'],
                      'category': data['categoryId'],
                      'categoryName':
                          categoryMap[data['categoryId']] ?? 'Unknown',
                      'description': data['description'],
                      'status': data['status'],
                      'timePosted': (data['timePosted'] as Timestamp?)
                          ?.toDate(),
                      'photos': List<String>.from(data['photos'] ?? []),
                    };
                  })
                  .where((l) {
                    if (user == null) return false;

                    // My listings
                    if (widget.isMyListings) {
                      if (l['sellerId'] != user.uid) return false;
                    } else {
                      if (l['sellerId'] == user.uid ||
                          l['status'] != 'ACTIVE') {
                        return false;
                      }
                    }

                    // Category filter
                    if (selectedCategoryId != null &&
                        l['category'] != selectedCategoryId) {
                      return false;
                    }

                    return true;
                  })
                  .toList();

              if (listings.isEmpty) {
                return const Center(child: Text('No listings found.'));
              }

              return Column(
                children: [
                  _buildCategoryDropdown(categoryMap),

                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 250,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.05,
                          ),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        return MarketplaceCard(data: listings[index]);
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
