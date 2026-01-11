import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/authentication/services/auth_service.dart';
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
  bool _loading = true;
  bool _offerSent = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkOfferStatus();
  }

  Future<void> _checkOfferStatus() async {
    final userId = AuthService().currentUser!.uid;
    final offersQuery = await _db
        .collection('requests')
        .doc(widget.requestId)
        .collection('offers')
        .where('offerUserId', isEqualTo: userId)
        .limit(1)
        .get();

    setState(() {
      _offerSent = offersQuery.docs.isNotEmpty;
      _loading = false;
    });
  }

  Future<void> _toggleOffer() async {
    setState(() => _loading = true);

    final userId = AuthService().currentUser!.uid;
    final offersRef = _db.collection('requests').doc(widget.requestId).collection('offers');

    if (_offerSent) {
      // Cancel the offer
      final existingQuery = await offersRef.where('offerUserId', isEqualTo: userId).limit(1).get();
      if (existingQuery.docs.isNotEmpty) {
        await offersRef.doc(existingQuery.docs.first.id).delete();
      }
      _offerSent = false;
    } else {
      // Send a new offer
      final newDoc = offersRef.doc();
      await newDoc.set({
        'offerId': newDoc.id,
        'offerStatus': 'pending',
        'offerUserId': userId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _offerSent = true;
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF155DFD);
    const hoverColor = Color.fromARGB(255, 4, 22, 190);

    if (_loading) {
      return SizedBox(
        height: 52,
        width: double.infinity,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

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
              backgroundColor: _offerSent ? const Color.fromARGB(255, 243, 149, 26) : (_hovered ? hoverColor : baseColor),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _offerSent ? 'Offer already sent. Check chat.' : 'Offer to Help',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
