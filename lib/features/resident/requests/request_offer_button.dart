import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/chats/page.dart';

class OfferHelpButton extends StatefulWidget {
  final String requestId;
  final String requesterId;
  final VoidCallback? onPressed;

  const OfferHelpButton({
    super.key,
    required this.requestId,
    required this.requesterId,
    this.onPressed,
  });

  @override
  State<OfferHelpButton> createState() => _OfferHelpButtonState();
}

class _OfferHelpButtonState extends State<OfferHelpButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF155DFD);
    const hoverColor = Color.fromARGB(255, 4, 22, 190);

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (widget.onPressed != null) {
                widget.onPressed!();
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatPage(
                      requestId: widget.requestId,
                      requesterId: widget.requesterId,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _hovered ? hoverColor : baseColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Offer to Help',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
