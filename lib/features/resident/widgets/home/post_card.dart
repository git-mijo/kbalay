import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../requests/request_details_page.dart';

class PostCard extends StatefulWidget {
  final String requestId;
  final String title;
  final String categoryName; // already resolved
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

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(widget.timePosted);
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailsPage(
              requestId: widget.requestId,
              isMyRequest: false,
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
                      ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        mouseCursor: WidgetStateMouseCursor.clickable,
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(WidgetState.hovered)) return const Color(0xFF0F4FE0);
                            return const Color(0xFF155DFD);
                          },
                        ),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                        elevation: WidgetStateProperty.resolveWith<double>(
                          (states) => states.contains(WidgetState.hovered) ? 2 : 0,
                        ),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      child: const Text(
                        'Offer help',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w100),
                      ),
                    ),
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
