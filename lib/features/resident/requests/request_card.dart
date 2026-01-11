import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/authentication/services/auth_service.dart';
import 'request_details_page.dart';

class PostCard extends StatefulWidget {
  final String requestId;
  final String title;
  final String categoryName;
  final String requesterName;
  final int helpersNeeded;
  final int helpersAccepted;
  final String status;
  final DateTime timePosted;
  final dynamic geoPoint;
  final dynamic isMyRequest;

  const PostCard({
    super.key,
    required this.requestId,
    required this.title,
    required this.categoryName,
    required this.requesterName,
    required this.helpersNeeded,
    required this.helpersAccepted,
    required this.status,
    required this.timePosted,
    required this.isMyRequest,
    this.geoPoint,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _hovered = false;
  bool _loadingOfferStatus = true;
  String? _myOfferStatus; // pending, Approved, Denied, or null

  @override
  void initState() {
    super.initState();
    _checkMyOfferStatus();
  }

  Future<void> _checkMyOfferStatus() async {
    final userId = AuthService().currentUser!.uid;

    final query = await FirebaseFirestore.instance
        .collection('requests')
        .doc(widget.requestId)
        .collection('offers')
        .where('offerUserId', isEqualTo: userId)
        .limit(1)
        .get();

    if (!mounted) return;

    setState(() {
      if (query.docs.isNotEmpty) {
        _myOfferStatus = query.docs.first.data()['offerStatus'] ?? 'pending';
      } else {
        _myOfferStatus = null;
      }
      _loadingOfferStatus = false;
    });
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(widget.timePosted);
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    // determine button properties based on offer status
    Color buttonColor = const Color(0xFF155DFD);
    String buttonText = "Offer help";
    bool buttonEnabled = true;

    switch (_myOfferStatus) {
      case 'Approved':
        buttonColor = Colors.green;
        buttonText = "Offer approved!";
        buttonEnabled = false;
        break;
      case 'Denied':
        buttonColor = Colors.redAccent;
        buttonText = "Offer denied";
        buttonEnabled = false;
        break;
      case 'pending':
        buttonColor = Colors.orangeAccent;
        buttonText = "Pending offer";
        buttonEnabled = false; // cannot send again
        break;
      default:
        buttonColor = const Color(0xFF155DFD);
        buttonText = "Offer help";
        buttonEnabled = true;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailsPage(
              requestId: widget.requestId,
              isMyRequest: widget.isMyRequest,
            ),
          ),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: Colors.grey.shade50,
          elevation: _hovered ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 221, 233, 255),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.categoryName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 47, 72, 156),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Posted by ${widget.requesterName} • ${widget.helpersAccepted} helpers accepted',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color.fromARGB(255, 73, 73, 73),
                    fontWeight: FontWeight.w100,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '👥 ${widget.helpersNeeded} helpers needed',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 73, 73, 73),
                        ),
                      ),
                    ),
                    if (widget.geoPoint != null)
                      const Text(
                        '📍 Nearby',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color.fromARGB(255, 73, 73, 73),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 88, 88, 88),
                        ),
                      ),
                    ),
                    if (widget.isMyRequest != true)
                      _loadingOfferStatus
                          ? const SizedBox(
                              height: 36,
                              width: 36,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : ElevatedButton(
                              onPressed: buttonEnabled
                                  ? () {
                                      // TODO: call offer help function here
                                    }
                                  : null,
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(buttonColor),
                                foregroundColor: MaterialStateProperty.all(Colors.white),
                                padding: MaterialStateProperty.all(
                                  const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                ),
                                shape: MaterialStateProperty.all(
                                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              child: Text(
                                buttonText,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w100),
                              ),
                            )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "My request",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
