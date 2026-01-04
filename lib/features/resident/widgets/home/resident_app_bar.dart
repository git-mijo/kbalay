import 'package:flutter/material.dart';

class ResidentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ResidentAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFF155DFD),
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Text('HOA Connect', style: TextStyle(color: Colors.white)),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                hoverColor: const Color.fromARGB(255, 17, 73, 195),
                splashColor: const Color.fromARGB(255, 17, 73, 195),
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.search, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                hoverColor: const Color.fromARGB(255, 17, 73, 195),
                splashColor: const Color.fromARGB(255, 17, 73, 195),
                onTap: () {},
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.notifications_none, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
