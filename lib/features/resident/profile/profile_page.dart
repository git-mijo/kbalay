import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/authentication/services/auth_service.dart';
import 'package:flutter_hoa/routes/app_routes.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  bool _loading = true;

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
      setState(() {
        _userData = snapshot.docs.first.data();
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userData == null) {
      return const Scaffold(
        body: Center(child: Text("User not found")),
      );
    }

    final fullName =
        "${_userData!['firstName'] ?? ''} ${_userData!['middleName'] ?? ''} ${_userData!['lastName'] ?? ''} ${_userData!['suffix'] ?? ''}"
            .trim();

    final email = _auth.currentUser?.email ?? '';
    final location = _userData!['fullAddress'] ?? '';
    final isAvailable = _userData!['isAvailable'] ?? false;
    final isRental = _userData!['isRental'] ?? false;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF1E5EFF),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.lightBlueAccent,
                        child: Text(
                          fullName.isNotEmpty ? fullName[0] : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(color: Colors.white70),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAvailable ? 'Available' : 'Not Available',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Availability Status',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        Icon(
                          isRental ? Icons.home_work : Icons.home,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ===== LOCATION =====
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
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(location),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ===== ACTIVITY =====
            _sectionTitle('Activity'),
            _infoCard(
              child: Column(
                children: const [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActivityItem('3', 'Requests Posted'),
                      _ActivityItem('12', 'Times Helped'),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActivityItem('15', 'Offers Made'),
                      _ActivityItem('98%', 'Response Rate'),
                    ],
                  ),
                ],
              ),
            ),

            // ===== BADGES =====
            _sectionTitle('Badges Earned'),
            _infoCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _BadgeItem(Icons.handshake, 'Helper'),
                  _BadgeItem(Icons.star, 'Trusted'),
                  _BadgeItem(Icons.emoji_events, 'Top 10'),
                ],
              ),
            ),

            // ===== PROFILE ACTION BUTTONS =====
            const SizedBox(height: 12),
            _profileActionButton(
              icon: Icons.settings,
              label: 'User Settings',
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.residentProfileSettings);
                // TODO: Navigate to Settings page
              },
            ),
            _profileActionButton(
              icon: Icons.help_outline,
              label: 'Help & Support',
              onTap: () {
                // TODO: Navigate to Help & Support page
              },
            ),
            _profileActionButton(
              icon: Icons.logout,
              label: 'Sign Out',
              isLogout: true,
              onTap: () async {
                try {
                  await authService.value.signOut();
                  Fluttertoast.showToast(
                    msg: 'Logged out successfully',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                  Navigator.pushReplacementNamed(context, AppRoutes.signIn);
                } catch (e) {
                  Fluttertoast.showToast(
                    msg: 'Failed to log out: $e',
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                  );
                }
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

/* ===== SMALL REUSABLE WIDGETS ===== */
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
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLogout ? Colors.red : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isLogout ? Colors.red : Colors.black87,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isLogout ? Colors.red : Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
}
