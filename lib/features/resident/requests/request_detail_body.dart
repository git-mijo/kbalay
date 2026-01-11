import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestDetailBody extends StatelessWidget {
  final Map<String, dynamic>? requestData;
  final String categoryName;

  const RequestDetailBody({
    super.key,
    required this.requestData,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if requestData is null
    if (requestData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Safely extract fields with default values
    final requesterName = (requestData!['requesterName'] as String?) ?? 'Anonymous';
    final helpersNeeded = (requestData!['helpersNeeded'] as int?) ?? 0;
    final helpersAccepted = (requestData!['helpersAccepted'] as int?) ?? 0;
    final description = (requestData!['description'] as String?) ?? 'No description';
    final isMyRequest = requestData!['isMyRequest'] == true;
    final geoPoint = requestData!['geoPoint'] as GeoPoint?;
    final distance = geoPoint != null ? "Nearby" : "N/A";
    final status = (requestData!['status'] as String?) ?? 'Open';
    final title = (requestData!['title'] as String?) ?? '';
    final String? base64String = requestData!['userImage'] as String?;
    final Uint8List? userImage = base64String != null && base64String.isNotEmpty
        ? base64Decode(base64String)
        : null;

    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title and Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
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
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.toLowerCase() == 'open'
                        ? Colors.green.shade700
                        : status.toLowerCase() == 'completed'
                            ? Colors.amber.shade800
                            : Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Requester Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.lightBlueAccent,
                  backgroundImage: userImage != null
                      ? MemoryImage(userImage)
                      : null,
                  child: userImage == null
                    ? Text(
                      requesterName.isNotEmpty ? requesterName[0].toUpperCase() : "U",
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    )
                  : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(requesterName, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        "$helpersAccepted helpers accepted • $helpersNeeded needed",
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Description",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(description, style: const TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 16),

            // Distance
            Row(
              children: [
                const Icon(Icons.location_pin, size: 16, color: Colors.black54),
                const SizedBox(width: 6),
                Text("Distance: $distance", style: const TextStyle(fontSize: 14)),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons for owner's request
            if (isMyRequest) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _updateRequest(context, requestData!),
                      child: const Text("Update Request"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _deleteRequest(context, requestData!['requestId'] as String?),
                      child: const Text("Delete Request"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Update request
  Future<void> _updateRequest(BuildContext context, Map<String, dynamic> data) async {
    final titleController = TextEditingController(text: (data['title'] as String?) ?? '');
    final descController = TextEditingController(text: (data['description'] as String?) ?? '');
    final helpersController = TextEditingController(text: ((data['helpersNeeded'] as int?) ?? 0).toString());

    final List<String> statusOptions = ['Open', 'In Progress', 'Completed'];
    String selectedStatus = (data['status'] as String?) ?? statusOptions.first;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Request"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              const SizedBox(height: 12),
              TextField(
                controller: helpersController,
                decoration: const InputDecoration(labelText: 'Helpers Needed'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: statusOptions.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                onChanged: (value) {
                  if (value != null) selectedStatus = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Update")),
        ],
      ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance.collection('requests').doc(data['requestId']).update({
          'title': titleController.text.trim(),
          'description': descController.text.trim(),
          'helpersNeeded': int.tryParse(helpersController.text.trim()) ?? 0,
          'status': selectedStatus,
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request updated successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update request: $e')));
      }
    }
  }

  // Delete request
  Future<void> _deleteRequest(BuildContext context, String? requestId) async {
    if (requestId == null || requestId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Request"),
        content: const Text("Are you sure you want to delete this request?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request deleted successfully')));
        Navigator.pop(context); // go back after deletion
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete request: $e')));
      }
    }
  }
}
