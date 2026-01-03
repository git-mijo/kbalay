import 'package:flutter/material.dart';

class RequestDetailOffers extends StatelessWidget {
  const RequestDetailOffers({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      child: Row(children: [Expanded(child: Text("Offers"))]),
    );
  }
}
