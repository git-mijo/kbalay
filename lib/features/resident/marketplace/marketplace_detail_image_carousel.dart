import 'package:flutter/material.dart';
import 'dart:convert';

class MarketplaceDetailImageCarousel extends StatefulWidget {
  final List<String> images;

  const MarketplaceDetailImageCarousel({super.key, required this.images});

  @override
  State<MarketplaceDetailImageCarousel> createState() =>
      _MarketplaceDetailImageCarouselState();
}

class _MarketplaceDetailImageCarouselState
    extends State<MarketplaceDetailImageCarousel> {
  int currentIndex = 0;

  void _next() {
    setState(() {
      if (currentIndex < widget.images.length - 1) currentIndex++;
    });
  }

  void _prev() {
    setState(() {
      if (currentIndex > 0) currentIndex--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.images.isNotEmpty
        ? Image.memory(
            base64Decode(widget.images[currentIndex]),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          )
        : Image.asset(
            'images/no-image-item.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          );

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Stack(
        children: [
          Positioned.fill(child: image),
          // Left arrow
          if (currentIndex > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45, // semi-transparent black
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: _prev,
                  ),
                ),
              ),
            ),

          // Right arrow
          if (currentIndex < widget.images.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45, // semi-transparent black
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    onPressed: _next,
                  ),
                ),
              ),
            ),

          // Optional page indicator
          if (widget.images.length > 1)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${currentIndex + 1}/${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
