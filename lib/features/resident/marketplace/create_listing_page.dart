import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';

class CreateListingPage extends StatefulWidget {
  const CreateListingPage({super.key});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Marketplace categories
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;

  List<XFile> _photos = [];
  bool _submitting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('marketplace_categories')
          .where('isActive', isEqualTo: true)
          .get();
      //TODO-QUERY:: need to add orderBy sortOrder, but needs composite index

      if (!mounted) return;

      setState(() {
        _categories = snapshot.docs.map((doc) {
          return {'id': doc.id, 'name': doc['categoryName'] as String};
        }).toList();
        _loadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('Error fetching categories: $e');
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _pickImages() async {
    final List<XFile>? picked = await _picker.pickMultiImage();
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _photos.addAll(picked);
      });
    }
  }

  static const bool _debugOnly = false;
  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;

    // =====================
    // DEBUG MODE (NO WRITE)
    // =====================
    if (_debugOnly) {
      debugPrint('🧪 CREATE LISTING (DEBUG MODE)');
      debugPrint('Title: ${_titleController.text}');
      debugPrint('Price: ${_priceController.text}');
      debugPrint('Category ID: $_selectedCategoryId');
      debugPrint('Description: ${_descriptionController.text}');
      debugPrint('Photos count: ${_photos.length}');
      debugPrint('Photo paths: ${_photos.map((p) => p.path).toList()}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DEBUG: Listing data logged to console')),
      );
      return;
    }

    // =====================
    // REAL SUBMIT LOGIC
    // =====================
    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Upload photos to Firebase Storage
      final List<String> photoUrls = [];

      for (final file in _photos) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('marketplace_listings')
            .child(user.uid)
            .child('${DateTime.now().millisecondsSinceEpoch}_${file.name}');

        await ref.putFile(File(file.path));
        final url = await ref.getDownloadURL();
        photoUrls.add(url);
      }

      // Create Firestore document
      await FirebaseFirestore.instance.collection('marketplace_listings').add({
        'title': _titleController.text.trim(),
        'price': double.parse(_priceController.text),
        'categoryId': _selectedCategoryId,
        'description': _descriptionController.text.trim(),
        'photos': photoUrls,
        'sellerId': user.uid,
        'status': 'ACTIVE',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing successfully created')),
      );

      Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ Create listing error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        backgroundColor: const Color(0xFF155DFD),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Create Listing', style: TextStyle(color: Colors.white)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== TITLE =====
              const Text(
                'Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter listing title',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),

              // ===== PRICE =====
              const Text(
                'Price (₱)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter price',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ===== CATEGORY =====
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _categories
                    .map<DropdownMenuItem<String>>(
                      (cat) => DropdownMenuItem<String>(
                        value: cat['id'] as String,
                        child: Text(cat['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
                validator: (value) =>
                    value == null ? 'Please select a category' : null,
                hint: _loadingCategories
                    ? const Text('Loading categories...')
                    : const Text('Select category'),
              ),
              const SizedBox(height: 16),

              // ===== DESCRIPTION =====
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter description',
                ),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 16),

              // ===== PHOTOS =====
              // const Text(
              //   'Photos',
              //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              // ),
              // const SizedBox(height: 8),
              // Wrap(
              //   spacing: 8,
              //   runSpacing: 8,
              //   children: [
              //     ..._photos.map(
              //       (file) => Stack(
              //         children: [
              //           Image.file(
              //             File(file.path),
              //             width: 80,
              //             height: 80,
              //             fit: BoxFit.cover,
              //           ),
              //           Positioned(
              //             right: 0,
              //             top: 0,
              //             child: GestureDetector(
              //               onTap: () {
              //                 setState(() {
              //                   _photos.remove(file);
              //                 });
              //               },
              //               child: Container(
              //                 color: Colors.black54,
              //                 child: const Icon(
              //                   Icons.close,
              //                   size: 16,
              //                   color: Colors.white,
              //                 ),
              //               ),
              //             ),
              //           ),
              //         ],
              //       ),
              //     ),
              //     GestureDetector(
              //       onTap: _pickImages,
              //       child: Container(
              //         width: 80,
              //         height: 80,
              //         color: Colors.grey[200],
              //         child: const Icon(
              //           Icons.add_a_photo,
              //           size: 30,
              //           color: Colors.grey,
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 30),

              // ===== SUBMIT BUTTON =====
              _submitting
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitListing,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: const Color(0xFF155DFD),
                        ),
                        child: const Text(
                          'Create Listing',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
