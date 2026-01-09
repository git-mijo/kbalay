import 'package:flutter/material.dart';

class RequestStatusBar extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final String status;

  const RequestStatusBar({
    super.key,
    this.backgroundColor = const Color.fromARGB(255, 255, 255, 255),
    this.textColor = const Color.fromARGB(255, 44, 44, 44),
    this.status = 'Open',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color.fromARGB(199, 191, 251, 196),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF276E50),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
