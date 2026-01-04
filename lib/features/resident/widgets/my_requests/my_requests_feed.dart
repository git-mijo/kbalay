import 'package:flutter/material.dart';
import 'my_requests_post_card.dart';

class MyRequestsFeed extends StatelessWidget {
  final int selectedIndex;

  const MyRequestsFeed({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final itemCount = selectedIndex == 0 ? 2 : 1;

    return Container(
      color: Colors.grey.shade50, // temporary
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const MyRequestsPostCard();
        },
      ),
    );
  }
}
