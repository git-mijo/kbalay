import 'package:flutter/material.dart';

class RequestDetailsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const RequestDetailsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 72,
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF155DFD),
      titleSpacing: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
        child: SizedBox(
          height: 40,
          width: 40,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_back, size: 24, color: Colors.white,),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Text(
          'Request Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
