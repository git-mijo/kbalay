import 'package:flutter/material.dart';

class ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProfileAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF155DFD),
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Text('My Profile', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
