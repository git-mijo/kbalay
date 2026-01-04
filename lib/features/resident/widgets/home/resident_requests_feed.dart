import 'package:flutter/material.dart';
import 'post_card.dart';

class ResidentRequestsFeed extends StatelessWidget {
  const ResidentRequestsFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade50, //temporary, may remove if there's theme
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (context, index) {
          return const PostCard();
        },
      ),
    );
  }
}
