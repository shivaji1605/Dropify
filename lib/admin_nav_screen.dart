import 'package:crypto_guide/admin_panel_screen.dart'; // This import is still needed
import 'package:flutter/material.dart';
import 'package:crypto_guide/admin_home_screen.dart';
import 'package:crypto_guide/admin_dashboard_page.dart'; // This is the file we want to show
import 'package:crypto_guide/admin_notification_screen.dart';
import 'package:crypto_guide/profile_screen.dart'; // Re-using the existing profile screen

class AdminNavScreen extends StatefulWidget {
  const AdminNavScreen({super.key});

  @override
  State<AdminNavScreen> createState() => _AdminNavScreenState();
}

class _AdminNavScreenState extends State<AdminNavScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- THIS LIST IS NOW CORRECTED ---
  static const List<Widget> _adminScreens = <Widget>[
    AdminHomeScreen(),        // Tab 1: Prices & News
    AdminDashboardPage(),     // Tab 2: The "Menu" screen (THIS IS THE FIX)
    AdminNotificationScreen(), // Tab 3: Send Notifications
    ProfileScreen(),          // Tab 4: Re-using the same profile screen
  ];
  // --- END OF FIX ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _adminScreens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.notifications), label: 'Notify'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        // Themed to match your app
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}