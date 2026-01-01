import 'package:flutter/material.dart';
import './post_card.dart';

class ResidentFeed extends StatelessWidget {
  const ResidentFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return const PostCard();
      },
    );
  }
}
