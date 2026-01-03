import 'package:flutter/material.dart';

import '../widgets/request_details/request_detail_body.dart';
import '../widgets/request_details/request_detail_offers.dart';
import '../widgets/request_details/request_section_tabs.dart';
import '../widgets/request_details/offer_help_button.dart';
import '../widgets/request_details/request_status_bar.dart';
import '../widgets/request_details/request_details_app_bar.dart';

class RequestDetailsPage extends StatefulWidget {
  const RequestDetailsPage({super.key});

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  int _selectedSectionIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RequestDetailsAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RequestStatusBar(),

          RequestSectionTabs(
            selectedIndex: _selectedSectionIndex,
            onChanged: (i) => setState(() => _selectedSectionIndex = i),
          ),

          Expanded(
            child: _selectedSectionIndex == 0
                ? const RequestDetailBody()
                : const RequestDetailOffers(),
          ),
        ],
      ),
      bottomNavigationBar: const OfferHelpButton(),
    );
  }
}
