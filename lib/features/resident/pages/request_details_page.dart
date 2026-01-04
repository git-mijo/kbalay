import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/resident/widgets/request_details/request_detail_chats.dart';

import '../widgets/request_details/request_detail_body.dart';
import '../widgets/request_details/request_detail_offers.dart';
import '../widgets/request_details/request_section_tabs.dart';
import '../widgets/request_details/offer_help_button.dart';
import '../widgets/request_details/request_status_bar.dart';
import '../widgets/request_details/request_details_app_bar.dart';

class RequestDetailsPage extends StatefulWidget {
  final bool isMyRequest; //temporary prop for frontend

  const RequestDetailsPage({super.key, this.isMyRequest = false});

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  int _selectedSectionIndex = 0;

  List<Widget> _buildSections() {
    final sections = <Widget>[
      const RequestDetailBody(),
      const RequestDetailOffers(),
    ];

    if (widget.isMyRequest) {
      sections.add(const RequestDetailChats());
    }

    return sections;
  }

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
            showChats: widget.isMyRequest,
            onChanged: (i) => setState(() => _selectedSectionIndex = i),
          ),

          Expanded(child: _buildSections()[_selectedSectionIndex]),
        ],
      ),
      bottomNavigationBar: widget.isMyRequest ? null : const OfferHelpButton(),
    );
  }
}
