import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.lightBlueAccent,
                        child: Text(
                          'M',
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Maria Santos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'maria_santos@gmail.com',
                            style: TextStyle(color: Colors.white70),
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
                      children: const [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '12',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tulog Count',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        Icon(Icons.emoji_events, color: Colors.white),
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
                children: const [
                  Icon(Icons.location_on, color: Colors.blue),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text('Barangay Commonwealth\nQuezon City'),
                    ],
                  ),
                ],
              ),
            ),

            // ===== ACTIVITY =====
            _sectionTitle('Activity'),
            _infoCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      _ActivityItem('3', 'Requests Posted'),
                      _ActivityItem('12', 'Times Helped'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
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
              label: 'Settings',
              onTap: () {
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
              label: 'Log Out',
              isLogout: true,
              onTap: () {
                // TODO: Add logout logic
              },
            ),

            const SizedBox(height: 80),
          ],
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
