import 'package:flutter/material.dart';

class OfferHelpButton extends StatefulWidget {
  final VoidCallback? onPressed;

  const OfferHelpButton({super.key, this.onPressed});

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
            onPressed: () {},
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
