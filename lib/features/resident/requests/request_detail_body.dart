import 'package:flutter/material.dart';

class RequestDetailBody extends StatelessWidget {
  final Map<String, dynamic> requestData;
  final String categoryName;

  const RequestDetailBody({
    super.key,
    required this.requestData,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final requesterName = requestData['requesterName'] ?? 'Anonymous';
    final helpersNeeded = requestData['helpersNeeded'] ?? 0;
    final helpersAccepted = requestData['helpersAccepted'] ?? 0;
    final description = requestData['description'] ?? 'No description';
    final isMyRequest = requestData['isMyRequest'];
    final distance = requestData['geoPoint'] != null ? "Nearby" : "N/A";

    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title & Category
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    requestData['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w100,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 221, 233, 255),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 47, 72, 156),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Requester info
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                              requesterName.isNotEmpty ? requesterName[0] : "U",
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(requesterName, style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(
                                "$helpersAccepted helpers accepted",
                                style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 75, 75, 75)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Description
            Row(
              children: [
                Expanded(
                  child: Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(description, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Helpers Needed & Distance
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.people, size: 16, color: Color.fromARGB(255, 75, 75, 75)),
                            SizedBox(width: 8),
                            Text("Helpers Needed", style: TextStyle(fontSize: 14, color: Color.fromARGB(255, 75, 75, 75))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text("$helpersNeeded People", style: const TextStyle(fontSize: 16, color: Colors.black)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.location_pin, size: 16, color: Color.fromARGB(255, 75, 75, 75)),
                            SizedBox(width: 8),
                            Text("Distance", style: TextStyle(fontSize: 14, color: Color.fromARGB(255, 75, 75, 75))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(distance, style: const TextStyle(fontSize: 16, color: Colors.black)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
