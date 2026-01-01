import 'package:flutter/material.dart';

import '../widgets/resident_app_bar.dart';
import '../widgets/resident_location_bar.dart';
import '../widgets/resident_section_tabs.dart';
import '../widgets/resident_feed.dart';
import '../widgets/resident_bottom_nav.dart';

class ResidentHomePage extends StatefulWidget {
  const ResidentHomePage({super.key});

  @override
  State<ResidentHomePage> createState() => _ResidentHomePageState();
}

class _ResidentHomePageState extends State<ResidentHomePage> {
  int _selectedBottomIndex = 0;
  int _selectedSectionIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ResidentAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ResidentLocationBar(),
          ResidentSectionTabs(
            selectedIndex: _selectedSectionIndex,
            onChanged: (index) {
              setState(() => _selectedSectionIndex = index);
            },
          ),
          const Expanded(child: ResidentFeed()),
        ],
      ),
      bottomNavigationBar: ResidentBottomNav(
        currentIndex: _selectedBottomIndex,
        onTap: (index) {
          setState(() => _selectedBottomIndex = index);
        },
      ),
    );
  }
}
