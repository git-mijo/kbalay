import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/resident/widgets/requests/request_detail_chats.dart';
import 'request_detail_body.dart';
import 'request_detail_offers.dart';
import 'request_section_tabs.dart';
import 'offer_help_button.dart';
import 'request_status_bar.dart';
import 'request_details_app_bar.dart';

class RequestDetailsPage extends StatefulWidget {
  final bool isMyRequest;
  final String requestId; // pass this from PostCard

  const RequestDetailsPage({super.key, required this.requestId, this.isMyRequest = false});

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  int _selectedSectionIndex = 0;

  Map<String, dynamic>? requestData;
  String categoryName = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadRequestData();
  }

  Future<void> _loadRequestData() async {
    // 1️⃣ Fetch request document
    final doc = await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).get();
    if (!doc.exists) return;
    final data = doc.data()!;

    final userRequester = await FirebaseFirestore.instance.collection('master_residents').where('userId', isEqualTo: data['requesterId']).limit(1).get();
    if (userRequester.docs.isNotEmpty) {
      final requesterDoc = userRequester.docs.first;
      final requesterName = requesterDoc['firstName'] ?? 'Unknown';
      final requesterLastName = requesterDoc['lastName'] ?? '';
      String fullName = "$requesterName $requesterLastName";
      data['requesterName'] = fullName;
    }

    // 2️⃣ Fetch category name from request_type
    final snapshot = await FirebaseFirestore.instance.collection('request_type').get();
    final Map<String, String> typeMap = {};
    for (var doc in snapshot.docs) {
      final dataRequesttype = doc.data();
      typeMap[dataRequesttype['rid']] = dataRequesttype['name'] ?? 'Unknown';
    }

    // Look up the category name using the request's category ID
    String catName = "Unknown";
    if (data['category'] != null && typeMap.containsKey(data['category'])) {
      catName = typeMap[data['category']]!;
    }
    
    setState(() {
      requestData = data;
      categoryName = catName;
    });
  }

  List<Widget> _buildSections() {
    if (requestData == null) {
      return [const Center(child: CircularProgressIndicator())];
    }

    final sections = <Widget>[
      RequestDetailBody(
        requestData: requestData!,
        categoryName: categoryName,
      ),
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
            showChats: true,
            onChanged: (i) => setState(() => _selectedSectionIndex = i),
          ),
          Expanded(child: _buildSections()[_selectedSectionIndex]),
        ],
      ),
      bottomNavigationBar: widget.isMyRequest ? null : const OfferHelpButton(),
    );
  }
}
