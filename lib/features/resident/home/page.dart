import 'package:flutter/material.dart';
import 'package:flutter_hoa/features/resident/my_requests/my_requests_feed.dart';
import 'package:flutter_hoa/features/resident/my_requests/my_requests_section_tabs.dart';
import '../profile/profile_page.dart';

import 'resident_app_bar.dart';
import 'resident_location_bar.dart';
import 'resident_section_tabs.dart';
import '../requests/requests_feed.dart';
import 'resident_announcements_feed.dart';
import '../widgets/resident_bottom_nav.dart';
import '../marketplace/marketplace_app_bar.dart';
import '../my_requests/my_requests_app_bar.dart';
import '../marketplace/marketplace_section_tabs.dart';
import '../marketplace/marketplace_listings_feed.dart';
import '../profile/profile_app_bar.dart';

class ResidentPage extends StatefulWidget {
  const ResidentPage({super.key});

  @override
  State<ResidentPage> createState() => _ResidentPageState();
}

class _ResidentPageState extends State<ResidentPage> {
  int _selectedBottomIndex = 0;
  int _selectedSectionIndex = 0;
  int _selectedMarketplaceIndex = 0;
  int _selectedMyRequestIndex = 0;

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        // Home tab
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResidentLocationBar(),
            ResidentSectionTabs(
              selectedIndex: _selectedSectionIndex,
              onChanged: (i) => setState(() => _selectedSectionIndex = i),
            ),
            Expanded(
              child: _selectedSectionIndex == 0
                  ? const ResidentRequestsFeed()
                  : const ResidentAnnouncementsFeed(),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarketplaceSectionTabs(
              selectedIndex: _selectedMarketplaceIndex,
              onChanged: (i) => setState(() => _selectedMarketplaceIndex = i),
            ),
            Expanded(
              child: MarketplaceListingsFeed(
                showCreateButton: _selectedMarketplaceIndex == 1,
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyRequestsSectionTabs(
              selectedIndex: _selectedMyRequestIndex,
              onChanged: (i) => setState(() => _selectedMyRequestIndex = i),
            ),
            Expanded(child: MyRequestsFeed()),
          ],
        );
      case 3:
        return const ProfilePage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _selectedBottomIndex == 0
          ? const ResidentAppBar()
          : _selectedBottomIndex == 1
          ? const MarketplaceAppBar()
          : _selectedBottomIndex == 2
          ? const MyRequestsAppBar()
          : const ProfileAppBar(),
      body: IndexedStack(
        index: _selectedBottomIndex,
        children: [_buildPage(0), _buildPage(1), _buildPage(2), _buildPage(3)],
      ),
      bottomNavigationBar: ResidentBottomNav(
        currentIndex: _selectedBottomIndex,
        onTap: (index) => setState(() => _selectedBottomIndex = index),
      ),
    );
  }
}
