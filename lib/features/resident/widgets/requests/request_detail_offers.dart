import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/resident/widgets/requests/request_offer_card.dart';

class RequestDetailOffers extends StatelessWidget {
  const RequestDetailOffers({super.key});
  final itemCount = 2;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return const RequestOfferCard();
        },
      ),
    );
  }
}
