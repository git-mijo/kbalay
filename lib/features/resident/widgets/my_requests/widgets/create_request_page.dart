import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({super.key});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController helpersNeededController = TextEditingController();

  String? selectedCategory;
  bool _loading = false;
  Map<String, String> requestTypes = {}; // rid → name

  @override
  void initState() {
    super.initState();
    _loadRequestTypes();
  }

  Future<void> _loadRequestTypes() async {
    final snapshot = await FirebaseFirestore.instance.collection('request_type').get();

    final Map<String, String> map = {};
    for (var doc in snapshot.docs) {
      map[doc['rid']] = doc['name'];
    }

    setState(() {
      requestTypes = map;
    });
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category")),
      );
      return;
    }

    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;

    // Fetch requester details
    final userSnapshot = await FirebaseFirestore.instance
        .collection('master_residents')
        .where('userId', isEqualTo: user!.uid)
        .limit(1)
        .get();

    final userData = userSnapshot.docs.first.data();
    final requesterName = "${userData['firstName']} ${userData['lastName']}".trim();

    // Generate new requestId
    final newDoc = FirebaseFirestore.instance.collection('requests').doc();

    await newDoc.set({
      'requestId': newDoc.id,
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'category': selectedCategory,
      'helpersNeeded': int.tryParse(helpersNeededController.text) ?? 1,
      'helpersAccepted': 0,
      'requesterId': user.uid,
      'requesterName': requesterName,
      'status': 'Open',
      'timePosted': FieldValue.serverTimestamp(),
      'geoPoint': userData['geoPoint'] ?? const GeoPoint(0, 0),
    });

    setState(() => _loading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create New Request"),
      ),
      body: requestTypes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                          labelText: "Request Type",
                          border: OutlineInputBorder()),
                      value: selectedCategory,
                      items: requestTypes.entries
                          .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedCategory = value);
                      },
                      validator: (value) => value == null ? "Required" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: helpersNeededController,
                      decoration: const InputDecoration(
                        labelText: "Helpers Needed",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _loading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Submit Request"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
