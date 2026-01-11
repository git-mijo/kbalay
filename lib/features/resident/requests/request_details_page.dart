import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/resident/requests/request_detail_chats.dart';
import 'request_detail_body.dart';
import 'request_detail_offers.dart';
import 'request_section_tabs.dart';
import 'request_offer_button.dart';
import 'request_status_bar.dart';
import 'request_details_app_bar.dart';

class RequestDetailsPage extends StatefulWidget {
  final bool isMyRequest;
  final String requestId; // pass this from PostCard

  const RequestDetailsPage({
    super.key,
    required this.requestId,
    required this.isMyRequest,
  });

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
    try {
      // 1️⃣ Fetch request document
      final doc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .get();
      if (!doc.exists) return;

      final data = doc.data()!;

      // 2️⃣ Fetch requester info
      if (data['requesterId'] != null) {
        final userSnap = await FirebaseFirestore.instance
            .collection('master_residents')
            .where('userId', isEqualTo: data['requesterId'])
            .limit(1)
            .get();

        if (userSnap.docs.isNotEmpty) {
          final requesterDoc = userSnap.docs.first;
          final firstName = requesterDoc['firstName'] ?? '';
          final lastName = requesterDoc['lastName'] ?? '';
          data['requesterName'] = "$firstName $lastName".trim();
          if (requesterDoc.data().containsKey('profileImageBase64')) {
            data['userImage'] = requesterDoc['profileImageBase64'];
          }
        } else {
          data['requesterName'] = "Unknown";
        }
      } else {
        data['requesterName'] = "Unknown";
      }

      // 3️⃣ Fetch category mapping
      final catSnap =
          await FirebaseFirestore.instance.collection('request_type').get();
      final Map<String, String> typeMap = {};
      for (var doc in catSnap.docs) {
        final catData = doc.data();
        typeMap[catData['rid']] = catData['name'] ?? 'Unknown';
      }

      final catName = (data['category'] != null && typeMap.containsKey(data['category']))
          ? typeMap[data['category']]!
          : "Unknown";

      data['isMyRequest'] = widget.isMyRequest;

      setState(() {
        requestData = data;
        categoryName = catName;
      });
    } catch (e) {
      debugPrint("Error loading request data: $e");
    }
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
      sections.add(RequestDetailChats(requestId: widget.requestId));
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    if (requestData == null) {
      // Show loading until data is ready
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const RequestDetailsAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RequestStatusBar(),
          if(widget.isMyRequest)
            RequestSectionTabs(
              selectedIndex: _selectedSectionIndex,
              showChats: widget.isMyRequest,
              onChanged: (i) => setState(() => _selectedSectionIndex = i),
            ),
          Expanded(child: _buildSections()[_selectedSectionIndex]),
        ],
      ),
      bottomNavigationBar: widget.isMyRequest || requestData == null
          ? null
          : OfferHelpButton(
              requestId: widget.requestId,
              requesterId: requestData!['requesterId'],
            ),
    );
  }
}
