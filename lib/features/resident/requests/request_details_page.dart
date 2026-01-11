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

  String categoryName = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadCategoryName();
  }

  // Load category mapping once (static data)
  Future<void> _loadCategoryName() async {
    try {
      final catSnap =
          await FirebaseFirestore.instance.collection('request_type').get();
      final Map<String, String> typeMap = {};
      for (var doc in catSnap.docs) {
        final catData = doc.data();
        typeMap[catData['rid']] = catData['name'] ?? 'Unknown';
      }

      setState(() {
        categoryName = typeMap.isNotEmpty ? typeMap.values.first : "Unknown";
      });
    } catch (e) {
      debugPrint("Error loading category data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Request not found")),
          );
        }

        final data = snapshot.data!.data()!;

        // Enrich data with requester info and user image
        // (You can also make this a separate async function if needed)
        if (data['requesterId'] != null) {
          FirebaseFirestore.instance
              .collection('master_residents')
              .where('userId', isEqualTo: data['requesterId'])
              .limit(1)
              .get()
              .then((userSnap) {
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
          });
        } else {
          data['requesterName'] = "Unknown";
        }

        data['isMyRequest'] = widget.isMyRequest;

        // Build the sections
        List<Widget> sections = [
          RequestDetailBody(requestData: data, categoryName: categoryName),
          RequestDetailOffers(requestId: data['requestId']),
        ];
        if (widget.isMyRequest) {
          sections.add(RequestDetailChats(requestId: widget.requestId));
        }

        return Scaffold(
          appBar: const RequestDetailsAppBar(),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isMyRequest)
                RequestSectionTabs(
                  selectedIndex: _selectedSectionIndex,
                  showChats: widget.isMyRequest,
                  onChanged: (i) => setState(() => _selectedSectionIndex = i),
                ),
              Expanded(child: sections[_selectedSectionIndex]),
            ],
          ),
          bottomNavigationBar: widget.isMyRequest || data == null
              ? null
              : OfferHelpButton(
                  requestId: widget.requestId,
                  requesterId: data['requesterId'],
                ),
        );
      },
    );
  }
}
