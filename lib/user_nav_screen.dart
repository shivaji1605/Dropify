// --- lib/UserNavScreen.dart ---
// This file is now responsible for the Home screen's AppBar and FAB

import 'package:flutter/material.dart';
import 'package:crypto_guide/home_screen.dart';
import 'package:crypto_guide/learning_screen.dart';
import 'package:crypto_guide/portfolio_screen.dart';
import 'package:crypto_guide/profile_screen.dart';
import 'package:crypto_guide/user_notification_drawer.dart';

// --- NEW IMPORTS (Moved from HomeScreen) ---
import 'package:crypto_guide/wallet_screen.dart';
import 'package:crypto_guide/track_coin_screen.dart';

class UserNavScreen extends StatefulWidget {
  const UserNavScreen({super.key});

  @override
  State<UserNavScreen> createState() => _UserNavScreenState();
}

class _UserNavScreenState extends State<UserNavScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // This list of screens is correct
  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    Learningscreen(),
    PortfolioScreen(),
    ProfileScreen(),
  ];

  // --- NEW: Helper function to build the AppBar for the Home screen ---
  AppBar _buildHomeAppBar(BuildContext context) {
    return AppBar(
      // The drawer icon will be added AUTOMATICALLY by the Scaffold
      title: const Text(
        'Drop Picker',
        style: TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.account_balance_wallet_outlined,
              color: Colors.black, size: 26),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WalletScreen()),
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16),
        ),
      ],
    );
  }

  // --- NEW: Helper function to build the FAB for the Home screen ---
  Widget _buildHomeFab(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'fab_user_home', // Use a unique Hero tag
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TrackCoinScreen()),
        );
      },
      label: const Text("Track Coin"),
      icon: const Icon(Icons.add),
      backgroundColor: Colors.orange,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This drawer will now correctly show on the Home screen
      drawer: const UserNotificationDrawer(),
      
      // --- MODIFICATION: The AppBar is now conditional ---
      // It only shows for the Home tab (index 0).
      // Other screens (like Learning) will provide their own.
      appBar: _selectedIndex == 0 ? _buildHomeAppBar(context) : null,

      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // --- MODIFICATION: The FAB is also conditional ---
      floatingActionButton: _selectedIndex == 0 ? _buildHomeFab(context) : null,

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Learning'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Portfolio'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo, 
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}