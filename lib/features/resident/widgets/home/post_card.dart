import 'package:flutter/material.dart';

import '../../pages/request_details_page.dart';

class PostCard extends StatefulWidget {
  const PostCard({super.key});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const RequestDetailsPage(
              isMyRequest: false,
            ), //temporary prop for frontend
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
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
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'Need friends for ML 5-man',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 221, 233, 255),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Fun & Games',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 47, 72, 156),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                const Text(
                  'Posted by Juan Dela Cruz • 8 Tulong',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color.fromARGB(255, 73, 73, 73),
                    fontWeight: FontWeight.w100,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: const [
                    Expanded(
                      child: Text(
                        '👥 2 helpers needed',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 73, 73, 73),
                        ),
                      ),
                    ),
                    Text(
                      '📍 800m away',
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
                    const Expanded(
                      child: Text(
                        '2 hours ago',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 88, 88, 88),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        mouseCursor: WidgetStateProperty.all(
                          SystemMouseCursors.basic,
                        ),
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(WidgetState.hovered)) {
                              return const Color(0xFF0F4FE0);
                            }
                            return const Color(0xFF155DFD);
                          },
                        ),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                        elevation: WidgetStateProperty.resolveWith<double>((
                          states,
                        ) {
                          if (states.contains(WidgetState.hovered)) return 2;
                          return 0;
                        }),
                        padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                        ),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Offer help',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w100,
                        ),
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
