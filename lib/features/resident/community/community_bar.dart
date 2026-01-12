import 'package:flutter/material.dart';

class CommunityBar extends StatelessWidget implements PreferredSizeWidget {
  const CommunityBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF155DFD),
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Text('Community', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
