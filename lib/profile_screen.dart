import 'package:flutter/material.dart';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto_guide/login_screen.dart'; 
import 'package:crypto_guide/custom_snackbar.dart'; 

import 'dart:io'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; // --- MODIFIED: Added Firestore ---

import 'edit_profile_screen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --- MODIFIED: These are now just for saving, not for state ---
  bool _pushNotifications = true;
  bool _portfolioVisibility = true;
  bool _darkMode = false;

  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // --- MODIFIED: Added Firestore instance ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _pickAndUploadImage() async {
    if (_isUploading) return; 

    setState(() {
      _isUploading = true;
    });

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

      if (image == null) {
        setState(() => _isUploading = false);
        return;
      }

      File imageFile = File(image.path);
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
         setState(() => _isUploading = false);
         return; 
      }

      final String storagePath = 'profile_photos/${currentUser.uid}/profile.jpg';
      final Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      await currentUser.updatePhotoURL(downloadUrl);
      await currentUser.reload();
      
      // --- MODIFIED: Save photoURL to Firestore as well ---
      // This makes the StreamBuilder update instantly.
      await _firestore.collection('users').doc(currentUser.uid).set({
        'photoURL': downloadUrl
      }, SetOptions(merge: true));

      if (mounted) {
        CustomSnackbar().showCustomSnackbar(context, "Profile photo updated!", bgColor: Colors.green);
        setState(() {
          _isUploading = false;
        });
      }

    } catch (e) {
      log("Error uploading image: $e");
      if (mounted) {
        CustomSnackbar().showCustomSnackbar(context, "Failed to update photo. Check permissions/rules.", bgColor: Colors.red);
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
     try {
      bool? confirmLogout = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to log out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false), // No
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true), // Yes
                child: const Text('Logout'),
              ),
            ],
          );
        },
      );

      if (confirmLogout != true) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await FirebaseAuth.instance.signOut();
      log("Logged out from Firebase");

      await GoogleSignIn().signOut();
      log("Logged out from Google");

      await prefs.setBool('isLoggedIn', false);
      log("Cleared SharedPreferences");

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      log("Error during logout: $e");
      if (context.mounted) {
        CustomSnackbar().showCustomSnackbar(
          context,
          "Logout failed: ${e.toString()}",
          bgColor: Colors.red,
        );
      }
    }
  }

  void _navigateToEditProfile(User? user) {
    if (user != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(currentUser: user),
        ),
      ).then((_) {
        // --- MODIFIED: No longer need to reload/setState here ---
        // The StreamBuilder will handle the update automatically.
        // user.reload();
        // setState(() {});
      });
    } else {
       log("Cannot navigate to edit profile: User is null or context is not mounted.");
    }
  }
  
  // --- NEW: Function to save settings ---
  Future<void> _saveSettings() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    final settingsMap = {
      'pushNotifications': _pushNotifications,
      'portfolioVisibility': _portfolioVisibility,
      'darkMode': _darkMode,
    };
    
    try {
      await _firestore.collection('users').doc(currentUser.uid).set({
        'settings': settingsMap
      }, SetOptions(merge: true));
      log("Settings saved to Firestore.");
    } catch (e) {
      log("Error saving settings: $e");
      if(mounted) {
        CustomSnackbar().showCustomSnackbar(context, "Could not save settings.", bgColor: Colors.red);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        if (authSnapshot.connectionState == ConnectionState.waiting) {
           return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (user == null) {
          // This should technically not be reached if Splash/Login logic is correct
          // But it's good practice to handle it.
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("You are not logged in."),
                  ElevatedButton(
                    child: const Text("Go to Login"),
                    onPressed: () {
                       Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (Route<dynamic> route) => false,
                      );
                    },
                  )
                ],
              ),
            ),
          );
        }

        // --- MODIFIED: Added StreamBuilder for live Firestore data ---
        return StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(user.uid).snapshots(),
          builder: (context, docSnapshot) {
            
            Map<String, dynamic>? userData;
            if (docSnapshot.connectionState == ConnectionState.active && docSnapshot.hasData && docSnapshot.data!.exists) {
              userData = docSnapshot.data!.data() as Map<String, dynamic>;
              
              // Load settings from Firestore, use current state as default
              final settings = userData['settings'] as Map<String, dynamic>? ?? {};
              _pushNotifications = settings['pushNotifications'] ?? _pushNotifications;
              _portfolioVisibility = settings['portfolioVisibility'] ?? _portfolioVisibility;
              _darkMode = settings['darkMode'] ?? _darkMode;
            }

            return Scaffold(
              backgroundColor: Colors.grey[100],
              appBar: AppBar(
                backgroundColor: Colors.grey[100],
                elevation: 0,
                centerTitle: false,
                automaticallyImplyLeading: false,
                title: const Text(
                  'Profile',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout_outlined, color: Colors.black54),
                    onPressed: () {
                      _logout(context);
                    },
                  ),
                ],
              ),
              body: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- MODIFIED: Pass user and userData to header ---
                  _buildProfileHeader(user, userData), 
                  const SizedBox(height: 24),
                  _buildSection(
                    icon: Icons.emoji_events_rounded,
                    title: 'Achievements',
                    child: _buildAchievementsList(),
                    action: '5 Earned',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    icon: Icons.bar_chart_rounded,
                    title: 'Your Statistics',
                    child: _buildStatisticsGrid(),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    icon: Icons.settings,
                    title: 'Settings',
                    // --- MODIFIED: Pass user data to settings ---
                    child: _buildSettingsList(userData),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildProfileHeader(User user, Map<String, dynamic>? userData) {
    // --- MODIFIED: Get photo and name from Firestore first, fallback to Auth ---
    final String photoUrl = userData?['photoURL'] ?? user.photoURL ?? '';
    final String displayName = userData?['displayName'] ?? user.displayName ?? 'Crypto User';

    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            InkWell(
              onTap: _pickAndUploadImage,
              borderRadius: BorderRadius.circular(35),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : const AssetImage('assets/images/dagdu.jpg') as ImageProvider,
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),
                  if (!_isUploading)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, spreadRadius: 1)]
                        ),
                        child: Icon(Icons.edit, size: 16, color: Colors.grey[700]),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName, // Use the new variable
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        user.metadata.creationTime != null
                            ? 'Joined ${MaterialLocalizations.of(context).formatMonthYear(user.metadata.creationTime!)}'
                            : 'Joined recently',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14)
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _navigateToEditProfile(user), // Pass auth user
              style: IconButton.styleFrom(backgroundColor: Colors.grey[200]),
              tooltip: 'Edit Profile Info',
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildSection({required IconData icon, required String title, required Widget child, String? action}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.black54),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const Spacer(),
                if (action != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Text(action, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsList() {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildAchievementItem(icon: Icons.quiz_outlined, label: 'First Quiz', isUnlocked: true),
          _buildAchievementItem(icon: Icons.local_fire_department_outlined, label: 'Learning Streak', isUnlocked: false),
          _buildAchievementItem(icon: Icons.trending_up_rounded, label: 'Portfolio Pro', isUnlocked: false),
          _buildAchievementItem(icon: Icons.wallet_giftcard_outlined, label: 'Airdrop Hunter', isUnlocked: true),
        ],
      ),
    );
  }

  Widget _buildAchievementItem({required IconData icon, required String label, bool isUnlocked = false}) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.orange : Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isUnlocked ? Colors.white : Colors.grey[500], size: 30),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: isUnlocked ? Colors.white : Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _buildStatItem(icon: Icons.quiz, value: '24', label: 'Quizzes Completed', color: Colors.blue),
        _buildStatItem(icon: Icons.school, value: '47h', label: 'Learning Hours', color: Colors.orange),
        _buildStatItem(icon: Icons.trending_up, value: '12.5%', label: 'Portfolio Performance', color: Colors.green),
        _buildStatItem(icon: Icons.wallet_giftcard, value: '8', label: 'Airdrops Joined', color: Colors.purple),
      ],
    );
  }

  Widget _buildStatItem({required IconData icon, required String value, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
            ],
          ),
          const Spacer(),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// Builds the list of settings toggles.
  Widget _buildSettingsList(Map<String, dynamic>? userData) {
    // --- MODIFIED: Load state from userData, fallback to local state ---
    final settings = userData?['settings'] as Map<String, dynamic>? ?? {};
    _pushNotifications = settings['pushNotifications'] ?? _pushNotifications;
    _portfolioVisibility = settings['portfolioVisibility'] ?? _portfolioVisibility;
    _darkMode = settings['darkMode'] ?? _darkMode;

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Push Notifications'),
          subtitle: const Text('Price alerts and airdrop deadlines'),
          value: _pushNotifications,
          onChanged: (bool value) {
            setState(() => _pushNotifications = value);
            _saveSettings(); // Save on change
          },
          secondary: Icon(Icons.notifications_outlined, color: Colors.grey[600]),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Portfolio Visibility'),
          subtitle: const Text('Show portfolio to other users'),
          value: _portfolioVisibility,
          onChanged: (bool value) {
             setState(() => _portfolioVisibility = value);
             _saveSettings(); // Save on change
          },
          secondary: Icon(Icons.visibility_outlined, color: Colors.grey[600]),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Switch to dark theme'),
          value: _darkMode,
          onChanged: (bool value) {
             setState(() => _darkMode = value);
             _saveSettings(); // Save on change
          },
          secondary: Icon(Icons.dark_mode_outlined, color: Colors.grey[600]),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
