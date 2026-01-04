import 'package:flutter/material.dart';

class RequestSectionTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool showChats;

  const RequestSectionTabs({
    super.key,
    required this.showChats,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = <String>['Details', 'Offers (0)', if (showChats) 'Chat'];

    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        color: const Color.fromARGB(
          255,
          255,
          255,
          255,
        ), //temporary, may remove if there's theme
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final isActive = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 50),

                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      width: 2,
                      color: isActive
                          ? const Color.fromARGB(255, 54, 117, 255)
                          : Colors.transparent,
                    ),
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    transform: isActive
                        ? (Matrix4.identity()
                            ..translate(0, -1)) // moves only the text
                        : Matrix4.identity(),
                    child: Text(
                      items[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w100,
                        color: isActive
                            ? const Color.fromARGB(255, 54, 117, 255)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
