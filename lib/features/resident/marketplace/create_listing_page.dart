import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

class CreateListingPage extends StatefulWidget {
  final String? listingId;
  final Map<String, dynamic>? initialData;

  const CreateListingPage({super.key, this.listingId, this.initialData});

  bool get isEdit => listingId != null && initialData != null;

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedCategoryId;
  String _status = 'ACTIVE';

  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;

  final ImagePicker _picker = ImagePicker();
  List<XFile> _newPhotos = [];
  List<String> _existingBase64Photos = [];

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();

    if (widget.isEdit) {
      final data = widget.initialData!;
      _titleController.text = data['title'] ?? '';
      _priceController.text = data['price'].toString();
      _descriptionController.text = data['description'] ?? '';
      _selectedCategoryId = data['category'];
      _status = data['status'] ?? 'ACTIVE';
      _existingBase64Photos = List<String>.from(data['photos'] ?? []);
    }
  }

  Future<void> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('marketplace_categories')
        .where('isActive', isEqualTo: true)
        .get();
    //TODO-QUERY:: need to add orderBy sortOrder, but needs composite index

    if (!mounted) return;

    setState(() {
      _categories = snapshot.docs
          .map((d) => {'id': d.id, 'name': d['categoryName']})
          .toList();
      _loadingCategories = false;
    });
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked != null) {
      setState(() => _newPhotos.addAll(picked));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final List<String> base64Photos = [..._existingBase64Photos];

      for (final file in _newPhotos) {
        final bytes = await file.readAsBytes();
        base64Photos.add(base64Encode(bytes));
      }

      final payload = {
        'title': _titleController.text.trim(),
        'price': double.parse(_priceController.text),
        'categoryId': _selectedCategoryId,
        'description': _descriptionController.text.trim(),
        'photos': base64Photos,
        'status': _status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final col = FirebaseFirestore.instance.collection('marketplace_listings');

      if (widget.isEdit) {
        await col.doc(widget.listingId).update(payload);
      } else {
        await col.add({
          ...payload,
          'sellerId': user.uid,
          'timePosted': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      final updatedListing = {
        ...payload,
        'listingId': widget.listingId,
        'sellerId': user.uid,
      };

      Navigator.pop(context, updatedListing);
    } catch (e) {
      debugPrint('❌ Submit error: $e');
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
        title: Text(widget.isEdit ? 'Edit Listing' : 'Create Listing'),
        backgroundColor: const Color(0xFF155DFD),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField('Title', _titleController),
              _buildPrice(),
              _buildCategory(),
              _buildField('Description', _descriptionController, lines: 4),

              if (widget.isEdit) _buildStatus(),

              const SizedBox(height: 16),
              const Text(
                'Photos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildPhotos(),

              const SizedBox(height: 24),
              _submitting
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF155DFD),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: Text(
                          widget.isEdit ? 'Save Changes' : 'Create Listing',
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    int lines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: lines,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPrice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Price', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          items: _categories
              .map(
                (c) => DropdownMenuItem<String>(
                  value: c['id'] as String,
                  child: Text(c['name'] as String),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedCategoryId = v),
          validator: (v) => v == null ? 'Required' : null,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _status,
          items: const [
            DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
            DropdownMenuItem(value: 'WITHDRAWN', child: Text('Withdrawn')),
          ],
          onChanged: (v) => setState(() => _status = v!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPhotos() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._existingBase64Photos.map(
          (b64) => Stack(
            children: [
              Image.memory(
                base64Decode(b64),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
              _removeButton(() {
                setState(() => _existingBase64Photos.remove(b64));
              }),
            ],
          ),
        ),
        ..._newPhotos.map(
          (file) => FutureBuilder<Uint8List>(
            future: file.readAsBytes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              return Stack(
                children: [
                  Image.memory(
                    snapshot.data!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                  _removeButton(() {
                    setState(() => _newPhotos.remove(file));
                  }),
                ],
              );
            },
          ),
        ),
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: 80,
            height: 80,
            color: Colors.grey[300],
            child: const Icon(Icons.add_a_photo),
          ),
        ),
      ],
    );
  }

  Widget _removeButton(VoidCallback onTap) {
    return Positioned(
      right: 0,
      top: 0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.black54,
          child: const Icon(Icons.close, size: 16, color: Colors.white),
        ),
      ),
    );
  }
}
