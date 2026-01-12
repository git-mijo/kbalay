import 'package:flutter/material.dart';

class ResidentLocationBar extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final String location;

  const ResidentLocationBar({
    super.key,
    this.backgroundColor = const Color(0xFFEFF6FF),
    this.textColor = const Color.fromARGB(255, 44, 44, 44),
    this.location = 'Barangay Commonwealth, Quezon City',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: const Border(
          bottom: BorderSide(
            color: Color.fromARGB(149, 165, 202, 232),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              location,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
