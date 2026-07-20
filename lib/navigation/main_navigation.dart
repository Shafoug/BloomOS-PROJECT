import 'package:flutter/material.dart';

import '../screens/home/home_screen.dart';
import '../screens/plants/plants_screen.dart';
import '../screens/scan/scan_screen.dart';
import '../screens/settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  final bool isGuest;

  const MainNavigation({
    super.key,
    required this.isGuest,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    _pages = [
      HomeScreen(isGuest: widget.isGuest),
      PlantsManagementScreen(isGuest: widget.isGuest),
      ScanScreen(isGuest: widget.isGuest),
      const SettingsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F5E9),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa),
            label: 'Plant',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}