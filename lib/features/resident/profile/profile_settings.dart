import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResidentProfileSettingsPage extends StatefulWidget {
  const ResidentProfileSettingsPage({super.key});

  @override
  State<ResidentProfileSettingsPage> createState() => _ResidentProfileSettingsPageState();
}

class _ResidentProfileSettingsPageState extends State<ResidentProfileSettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  // Profile info controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _suffixController = TextEditingController();
  final TextEditingController _fullAddressController = TextEditingController();

  // Password controllers
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _loading = true;
  bool _updating = false;
  String? _docId;

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
      _fullAddressController.text = data['fullAddress'] ?? '';
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _updating = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // --- UPDATE FIRESTORE PROFILE INFO ---
      if (_docId != null) {
        await _db.collection('master_residents').doc(_docId).update({
          'firstName': _firstNameController.text.trim(),
          'middleName': _middleNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'suffix': _suffixController.text.trim(),
          'fullAddress': _fullAddressController.text.trim(),
        });
      }

      // --- UPDATE PASSWORD IF ENTERED ---
      if (_passwordController.text.isNotEmpty) {
        if (_passwordController.text != _confirmPasswordController.text) {
          Fluttertoast.showToast(msg: "New passwords do not match");
          setState(() => _updating = false);
          return;
        }

        if (_oldPasswordController.text.isEmpty) {
          Fluttertoast.showToast(msg: "Please enter your current password");
          setState(() => _updating = false);
          return;
        }

        // Re-authenticate user with old password
        final cred = EmailAuthProvider.credential(
            email: user.email!, password: _oldPasswordController.text.trim());
        try {
          await user.reauthenticateWithCredential(cred);
          await user.updatePassword(_passwordController.text.trim());
        } on FirebaseAuthException catch (e) {
          Fluttertoast.showToast(msg: "Current password is incorrect: ${e.message}");
          setState(() => _updating = false);
          return;
        }
      }

      Fluttertoast.showToast(msg: 'Profile updated successfully');
      Navigator.pop(context); // Go back to profile page
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
              // ===== PROFILE INFO SECTION =====
              const Text(
                'Profile Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTextField('First Name', _firstNameController),
              _buildTextField('Middle Name', _middleNameController),
              _buildTextField('Last Name', _lastNameController),
              _buildTextField('Suffix', _suffixController),
              _buildTextField('Full Address', _fullAddressController, maxLines: 2),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // ===== CHANGE PASSWORD SECTION =====
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTextField('Current Password', _oldPasswordController, obscureText: true),
              _buildTextField('New Password', _passwordController, obscureText: true),
              _buildTextField('Confirm New Password', _confirmPasswordController, obscureText: true),

              const SizedBox(height: 30),
              _updating
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: const Color(0xFF1E5EFF),
                        ),
                        child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool obscureText = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLines: maxLines,
        validator: (value) {
          // Only require old password if new password is entered
          if (label == 'Current Password' && _passwordController.text.isNotEmpty) {
            if (value == null || value.isEmpty) return 'Current password required';
          }

          if ((label != 'Suffix' && label != 'Middle Name' && !label.contains('Password')) &&
              (value == null || value.isEmpty)) {
            return '$label cannot be empty';
          }

          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
