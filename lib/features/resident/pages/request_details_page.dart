import 'package:flutter/material.dart';

import '../widgets/request_details/request_details_app_bar.dart';

class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RequestDetailsAppBar(),
      body: const Center(
        child: Text(
          'Request Details Content Here',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
