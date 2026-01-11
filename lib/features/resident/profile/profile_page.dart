import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/authentication/services/auth_service.dart';
import 'package:flutter_hoa/routes/app_routes.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  late final int _responseRate;

  Future<void> _pickAndSaveBase64Image(String docId) async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40,
    );

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    await _db
        .collection('master_residents')
        .doc(docId)
        .update({'profileImageBase64': base64Image});
  }

  @override
  void initState() {
    super.initState();
    _responseRate = 60 + Random().nextInt(41); // 60%–100%
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    final bool isViewingOtherUser = widget.userId != null;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not logged in")),
      );
    }

    final profileUserId = widget.userId ?? user!.uid;


    return Scaffold(
      appBar: isViewingOtherUser
      ? AppBar(
          title: const Text("Seller's Profile"),
          leading: const BackButton(),
        )
      : null,
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('master_residents')
            .where('userId', isEqualTo: profileUserId)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("User not found"));
          }

          final doc = snapshot.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          final bool isOwner = data['userId'] == user.uid;

          final fullName =
              "${data['firstName'] ?? ''} ${data['middleName'] ?? ''} ${data['lastName'] ?? ''} ${data['suffix'] ?? ''}"
                  .trim();

          final email = user.email ?? '';

          final phase = data['phase'];
          final block = data['block'];
          final lot = data['lotNumber'];
          final fullAddress = data['fullAddress'];

          final List<String> locationParts = [];
          if ((phase ?? '').toString().isNotEmpty) {
            locationParts.add('Phase $phase');
          }
          if ((block ?? '').toString().isNotEmpty) {
            locationParts.add('Block $block');
          }
          if ((lot ?? '').toString().isNotEmpty) {
            locationParts.add('Lot $lot');
          }
          if ((fullAddress ?? '').toString().isNotEmpty) {
            locationParts.add(fullAddress);
          }

          final location = locationParts.join(', ');

          final isAvailable = data['isAvailable'] ?? false;
          final isRental = data['isRental'] ?? false;

          final roleLabel = isRental ? 'Tenant' : 'Unit Owner';
          final roleColor = isRental ? Colors.orange : Colors.green;

          Uint8List? imageBytes = data['profileImageBase64'] != null
              ? base64Decode(data['profileImageBase64'])
              : null;

          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  color: const Color(0xFF1E5EFF),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: isOwner ? () => _pickAndSaveBase64Image(doc.id) : null,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 42,
                                  backgroundColor: Colors.lightBlueAccent,
                                  backgroundImage: imageBytes != null
                                      ? MemoryImage(imageBytes)
                                      : null,
                                  child: imageBytes == null
                                      ? Text(
                                          fullName.isNotEmpty
                                              ? fullName[0]
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 36,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                if (isOwner)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: roleColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  roleLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isOwner)
                                Text(
                                  email,
                                  style:
                                      const TextStyle(color: Colors.white70),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isAvailable
                                      ? 'Available'
                                      : 'Not Available',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Availability Status',
                                  style: TextStyle(
                                      color: Colors.white70),
                                ),
                              ],
                            ),
                            Icon(
                              isRental
                                  ? Icons.home_work
                                  : Icons.home,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _infoCard(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location',
                              style:
                                  TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(location),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                _sectionTitle('Activity'),
                _infoCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('requests')
                                .where('requesterId', isEqualTo: profileUserId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const _ActivityItem('0', 'Requests Posted');
                              }

                              final count = snapshot.data!.docs.length;

                              return _ActivityItem(
                                count.toString(),
                                'Requests Posted',
                              );
                            },
                          ),
                          const _ActivityItem('12', 'Times Helped'),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceAround,
                        children: [
                          _ActivityItem('15', 'Offers Made'),
                          _ActivityItem('$_responseRate%', 'Response Rate'),

                        ],
                      ),
                    ],
                  ),
                ),

                _sectionTitle('Badges Earned'),
                _infoCard(
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                    children: const [
                      _BadgeItem(Icons.handshake, 'Helper'),
                      _BadgeItem(Icons.star, 'Trusted'),
                      _BadgeItem(Icons.emoji_events, 'Top 10'),
                    ],
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(height: 12),
                  _profileActionButton(
                    icon: Icons.settings,
                    label: 'Profile Settings',
                    onTap: () async {
                      await Navigator.pushNamed(
                          context,
                          AppRoutes.residentProfileSettings);
                    },
                  ),
                  _profileActionButton(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    onTap: () {},
                  ),
                  _profileActionButton(
                    icon: Icons.logout,
                    label: 'Sign Out',
                    isLogout: true,
                    onTap: () async {
                      await authService.value.signOut();
                      Fluttertoast.showToast(
                          msg: 'Logged out successfully');
                      Navigator.pushReplacementNamed(
                          context, AppRoutes.signIn);
                    },
                  ),

                  const SizedBox(height: 80),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _infoCard({required Widget child}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 4),
      ],
    ),
    child: child,
  );
}

Widget _sectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

class _ActivityItem extends StatelessWidget {
  final String value;
  final String label;

  const _ActivityItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _BadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BadgeItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}

Widget _profileActionButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  bool isLogout = false,
}) {
  return InkWell(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLogout ? Colors.red : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: isLogout ? Colors.red : Colors.black87),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color:
                  isLogout ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
}
