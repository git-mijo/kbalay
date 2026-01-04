import 'package:flutter/material.dart';

class RequestOfferCard extends StatelessWidget {
  const RequestOfferCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color.fromARGB(255, 255, 255, 255),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color.fromARGB(255, 224, 224, 224),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 61, 122, 255),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Center(
                child: Text(
                  "J",
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: (Text(
                          "Juan Dela Cruz",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        )),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 211, 255, 216),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Accepted',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 32, 138, 46),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    "18 hours ago",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 75, 75, 75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
