import 'package:flutter/material.dart';

class MyRequestsPostCard extends StatefulWidget {
  const MyRequestsPostCard({super.key});

  @override
  State<MyRequestsPostCard> createState() => _MyRequestsPostCardState();
}

class _MyRequestsPostCardState extends State<MyRequestsPostCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
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
                        color: const Color.fromARGB(255, 248, 245, 163),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'In Progress',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color.fromARGB(255, 138, 132, 32),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 2),

                const Text(
                  'Fun & Games',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color.fromARGB(255, 73, 73, 73),
                    fontWeight: FontWeight.w100,
                  ),
                ),

                const SizedBox(height: 12),

                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color.fromARGB(255, 222, 222, 222),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '2 offers',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color.fromARGB(255, 73, 73, 73),
                        ),
                      ),
                    ),
                    Text(
                      '1 day ago',
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(168, 225, 255, 237),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color.fromARGB(188, 126, 255, 165),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "Accepted: Pedro Reyes",
                          style: TextStyle(
                            color: const Color.fromARGB(184, 2, 50, 15),
                          ),
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
