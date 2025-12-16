import 'package:flutter/material.dart';
import '../home/home_page.dart';
import '../search/search_page.dart';
import '../analytics/analytics_page.dart';
import '../settings/settings_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final pages = const [
    HomePage(),
    SearchPage(),
    AnalyticsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final inactiveBg = theme.brightness == Brightness.dark
      ? const Color(0xFF2A2A2A)
      : Colors.grey.shade300;
    
    final inactiveIcon =
      theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: IndexedStack(
        index: _index,
        children: pages,
      ),

      // === Figma Bottom Navbar ===
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navItem(
                  icon: Icons.home_filled,
                  index: 0,
                  inactiveBg: inactiveBg,
                  inactiveIcon: inactiveIcon,
                ),
                _navItem(
                  icon: Icons.search_rounded,
                  index: 1,
                  inactiveBg: inactiveBg,
                  inactiveIcon: inactiveIcon,
                ),
                _navItem(
                  icon: Icons.bar_chart_rounded,
                  index: 2,
                  inactiveBg: inactiveBg,
                  inactiveIcon: inactiveIcon,
                ),
                _navItem(
                  icon: Icons.settings_rounded,
                  index: 3,
                  inactiveBg: inactiveBg,
                  inactiveIcon: inactiveIcon,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({required IconData icon, required int index, required Color inactiveBg, required Color inactiveIcon}) {
    final isActive = _index == index;

    return GestureDetector(
      onTap: () => setState(() => _index = index),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? const Color(0xFF4A90E2) : inactiveBg,
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive ? Colors.white : inactiveIcon,
        ),
      ),
    );
  }
}
