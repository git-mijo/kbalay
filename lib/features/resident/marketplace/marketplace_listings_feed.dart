import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './marketplace_card.dart';
import './create_listing_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MarketplaceListingsFeed extends StatelessWidget {
  final bool isMyListings;

  const MarketplaceListingsFeed({super.key, this.isMyListings = false});

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

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateListingPage()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Create Listing"),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Future.wait([_fetchCategories(), _fetchUsers()]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            debugPrint('Error fetching categories/users: ${snapshot.error}');
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
              if (listingsSnapshot.hasError) {
                debugPrint(
                  'Error fetching listings: ${listingsSnapshot.error}',
                );
                return const Center(child: Text('Error loading listings'));
              }
              if (!listingsSnapshot.hasData ||
                  listingsSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No listings found.'));
              }

              final docs = listingsSnapshot.data!.docs;

              final listings = docs
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
                    if (user == null) return true;

                    if (isMyListings) {
                      // My listings: keep all statuses
                      return l['sellerId'] == user.uid;
                    } else {
                      // Others: only ACTIVE
                      return l['sellerId'] != user.uid &&
                          l['status'] == 'ACTIVE';
                    }
                  })
                  .toList();

              if (listings.isEmpty) {
                return const Center(child: Text('No listings found.'));
              }

              return GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 0,
                  childAspectRatio: 1.05,
                ),
                itemCount: listings.length,
                itemBuilder: (context, index) {
                  return MarketplaceCard(data: listings[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}
