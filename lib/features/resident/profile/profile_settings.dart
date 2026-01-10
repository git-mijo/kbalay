import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ResidentProfileSettingsPage extends StatefulWidget {
  const ResidentProfileSettingsPage({super.key});

  @override
  State<ResidentProfileSettingsPage> createState() =>
      _ResidentProfileSettingsPageState();
}

class _ResidentProfileSettingsPageState
    extends State<ResidentProfileSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  // Profile info controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();

  // Address controllers
  final TextEditingController _phaseController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _lotNumberController = TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();

  // Password controllers
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _loading = true;
  bool _updating = false;
  String? _docId;
  String? _profileImageBase64;

  bool _isAvailable = false;
  bool _isRental = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _db
        .collection('master_residents')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      _docId = snapshot.docs.first.id;

      _firstNameController.text = data['firstName'] ?? '';
      _middleNameController.text = data['middleName'] ?? '';
      _lastNameController.text = data['lastName'] ?? '';
      _suffixController.text = data['suffix'] ?? '';

      _phaseController.text = data['phase'] ?? '';
      _blockController.text = data['block'] ?? '';
      _lotNumberController.text = data['lotNumber'] ?? '';
      _fullAddressController.text = data['fullAddress'] ?? '';

      _isAvailable = data['isAvailable'] ?? false;
      _isRental = data['isRental'] ?? false;

      _profileImageBase64 = data['profileImageBase64'];
    }

    setState(() => _loading = false);
  }

  Future<void> _pickAndSaveProfileImage() async {
    if (_docId == null) return;

    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();

    if (bytes.lengthInBytes > 500 * 1024) {
      Fluttertoast.showToast(msg: 'Image too large');
      return;
    }

    final base64Image = base64Encode(bytes);

    await _db
        .collection('master_residents')
        .doc(_docId)
        .update({'profileImageBase64': base64Image});

    setState(() => _profileImageBase64 = base64Image);
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _updating = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _db.collection('master_residents').doc(_docId).update({
        'firstName': _firstNameController.text.trim(),
        'middleName': _middleNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'suffix': _suffixController.text.trim(),
        'phase': _phaseController.text.trim(),
        'block': _blockController.text.trim(),
        'lotNumber': _lotNumberController.text.trim(),
        'fullAddress': _fullAddressController.text.trim(),
        'isAvailable': _isAvailable,
        'isRental': _isRental,
      });

      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmPasswordController.text) {
          Fluttertoast.showToast(msg: "New passwords do not match");
          setState(() => _updating = false);
          return;
        }

        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: _oldPasswordController.text.trim(),
        );

        await user.reauthenticateWithCredential(cred);
        await user.updatePassword(_passwordController.text.trim());
      }

      Fluttertoast.showToast(msg: 'Profile updated successfully');
      Navigator.pop(context);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Failed to update profile: $e');
    }

    setState(() => _updating = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Uint8List? imageBytes = _profileImageBase64 != null
        ? base64Decode(_profileImageBase64!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: const Color(0xFF1E5EFF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickAndSaveProfileImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 64,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage:
                            imageBytes != null ? MemoryImage(imageBytes) : null,
                        child: imageBytes == null
                            ? const Icon(Icons.person,
                                size: 48, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text('Profile Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField('First Name', _firstNameController, required: true),
              _buildTextField('Middle Name', _middleNameController),
              _buildTextField('Last Name', _lastNameController, required: true),
              _buildTextField('Suffix', _suffixController),

              const Divider(),

              const Text('Address Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                      child: _buildTextField('Phase', _phaseController,
                          required: true)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildTextField('Block', _blockController,
                          required: true)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _buildTextField('Lot', _lotNumberController,
                          required: true)),
                ],
              ),
              _buildTextField(
                'Full Address',
                _fullAddressController,
                required: true,
                maxLines: 2,
                helperText: 'Street, House #, etc.',
              ),

              SwitchListTile(
                title: const Text('Unit is Available (For Rent/Sale)'),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
              ),
              SwitchListTile(
                title: const Text('I am a Tenant'),
                value: _isRental,
                onChanged: (v) => setState(() => _isRental = v),
              ),

              const Divider(),

              const Text('Change Password',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField('Current Password', _oldPasswordController,
                  obscureText: true),
              _buildTextField('New Password', _passwordController,
                  obscureText: true),
              _buildTextField(
                  'Confirm New Password', _confirmPasswordController,
                  obscureText: true),

              const SizedBox(height: 30),
              _updating
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        child: const Text('Save Changes'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool required = false,
    bool obscureText = false,
    int maxLines = 1,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return '$label is required';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
