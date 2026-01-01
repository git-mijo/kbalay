import 'package:flutter/material.dart';

class ResidentLocationBar extends StatelessWidget {
  const ResidentLocationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: const [
          Icon(Icons.location_on_outlined, size: 18),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'Subdivision • Phase 2',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
