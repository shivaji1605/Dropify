// --- lib/AdminDashboardPage.dart ---
// (This file is correct. NO CHANGES NEEDED.)

import 'package:flutter/material.dart';
import 'package:crypto_guide/admin_panel_screen.dart'; // Add Airdrop
import 'package:crypto_guide/video_editor_screen.dart'; // Add Video
import 'package:crypto_guide/user_list_screen.dart'; // View Users

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            "Management Tools",
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 30),
          
          // This button is safe and works
          _buildAdminCard(
            context,
            icon: Icons.shield_outlined,
            title: "View User Analytics",
            subtitle: "See user portfolios and learning progress.",
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const UserListScreen()));
            },
          ),

          // This button is safe and works
          _buildAdminCard(
            context,
            icon: Icons.card_giftcard,
            title: "Manage Airdrops",
            subtitle: "Add or edit airdrops for the Home Screen.",
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()));
            },
          ),

          // This button is safe and works
          _buildAdminCard(
            context,
            icon: Icons.video_collection,
            title: "Manage Videos",
            subtitle: "Add or edit videos for the Learning Screen.",
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const VideoEditorScreen()));
            },
          ),
        ],
      ),
    );
  }

  // Helper widget
  Widget _buildAdminCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 40, color: Colors.indigo),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}