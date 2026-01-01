import 'package:flutter/material.dart';

class ResidentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ResidentAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF155DFD),
      foregroundColor: Colors.white,
      title: const Text('HOA Connect'),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
