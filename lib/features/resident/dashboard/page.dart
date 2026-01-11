import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_hoa/features/authentication/services/auth_service.dart';
import 'package:flutter_hoa/features/resident/payment/history.dart';
import 'package:flutter_hoa/features/resident/payment/manage.dart';
import 'package:flutter_hoa/features/resident/payment/pay.dart';
import 'package:flutter_hoa/features/resident/requests/request_details_page.dart';
import 'package:flutter_hoa/features/resident/requests/request_offer_card.dart';
import 'package:intl/intl.dart';

class UserDashboardPage extends StatelessWidget {
  const UserDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SectionTitle(title: "Latest Announcements", icon: Icons.announcement),
            SizedBox(height: 8),
            AnnouncementsSection(),

            SizedBox(height: 24),
            SectionTitle(title: "My Offers", icon: Icons.handshake),
            SizedBox(height: 8),
            MyOffersSection(),

            SizedBox(height: 24),
            SectionTitle(title: "Payment Management", icon: Icons.payment),
            SizedBox(height: 8),
            PaymentManagementSection(),

            SizedBox(height: 24),
            SectionTitle(title: "Other Info", icon: Icons.info),
            SizedBox(height: 8),
            OtherInfoSection(),
          ],
        ),
      ),
    );
  }
}

/// -------------------- Section Title Widget --------------------
class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionTitle({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

/// -------------------- Announcements Section --------------------
class AnnouncementsSection extends StatelessWidget {
  const AnnouncementsSection({super.key});

  String formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    return DateFormat('MMM d, yyyy – hh:mm a').format(date); 
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('timePosted', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final announcements = snapshot.data!.docs;

        if (announcements.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("No announcements yet."),
          );
        }

        return Column(
          children: announcements.map((doc) {
            final data = doc.data()! as Map<String, dynamic>;
            return Card(
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                dense: true, // makes it more compact
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: data['isCritical'] == true
                    ? Container(
                        width: 6,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      )
                    : null,
                title: Text(
                  data['title'] ?? 'No title',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: data['description'] != null
                    ? Text(
                        data['description'],
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: Text(
                  formatTimestamp(data['timePosted']),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            );

          }).toList(),
        );
      },
    );
  }
  
}

/// -------------------- My Offers Section --------------------
class MyOffersSection extends StatelessWidget {

  const MyOffersSection({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userId = AuthService().currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      // Query all offers made by this user across all requests
      stream: FirebaseFirestore.instance
          .collectionGroup('offers')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "You haven't made any offers yets.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        final offers = snapshot.data!.docs
          .where((doc) => doc['offerUserId'] == userId)
          .toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: offers.length,
          itemBuilder: (context, index) {
            final offer = offers[index];
            final offerData = offer.data() as Map<String, dynamic>;

            final requestRef = offer.reference.parent.parent;
            final timestamp = offerData['timestamp'] as Timestamp?;
            final status = offerData['offerStatus'] ?? 'Pending';

            return FutureBuilder<DocumentSnapshot>(
              future: requestRef!.get(),
              builder: (context, reqSnapshot) {
                if (!reqSnapshot.hasData) {
                  return const SizedBox();
                }

                final requestData = reqSnapshot.data!.data() as Map<String, dynamic>;
                final requestTitle = requestData['title'] ?? 'Unknown Request';
                final requesterId = requestData['requesterId'] ?? '';

                return InkWell(
                  borderRadius: BorderRadius.circular(12), // matches the Card's shape
                  onTap: () {
                    // Navigate to RequestDetailPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RequestDetailsPage(
                          requestId: requestData['requestId'],
                          isMyRequest: false,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          // Request info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  requestTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (timestamp != null)
                                  Text(
                                    'Offered on: ${DateFormat.yMMMd().add_jm().format(timestamp.toDate())}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black54,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: $status',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: status == 'Approved'
                                        ? Colors.green
                                        : status == 'Denied'
                                            ? Colors.red
                                            : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );

              },
            );
          },
        );
      },
    );
  }
}

/// -------------------- Payment Section --------------------
class PaymentManagementSection extends StatelessWidget {
  const PaymentManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min, // make height fit content
          children: [
            _buildOption(
              context,
              icon: Icons.list_alt,
              title: "Manage Dues",
              subtitle: "View your pending dues",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageDuesPage()),
                );
              },
            ),
            const Divider(height: 16, thickness: 1),
            _buildOption(
              context,
              icon: Icons.history,
              title: "Payment History",
              subtitle: "View your previous payments",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentHistoryPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}


/// -------------------- Other Info Section --------------------
class OtherInfoSection extends StatelessWidget {
  const OtherInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text("Other user-related info placeholder", style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}
