import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer'; 
import 'custom_snackbar.dart'; 

import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final User currentUser;

  const EditProfileScreen({super.key, required this.currentUser});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _displayNameController;
  late TextEditingController _walletAddressController;
  late TextEditingController _twitterController;
  late TextEditingController _discordController;
  late TextEditingController _telegramController;

  final _formKey = GlobalKey<FormState>(); // For form validation

  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    // Initialize controllers - displayName comes from Auth
    _displayNameController = TextEditingController(text: widget.currentUser.displayName ?? '');
    // Initialize others as empty, will be filled by _loadUserData
    _walletAddressController = TextEditingController();
    _twitterController = TextEditingController();
    _discordController = TextEditingController();
    _telegramController = TextEditingController();

    // --- ADDED: Load existing user data from Firestore ---
    _loadUserData();
  }

  // --- ADDED: Function to load data from Firestore ---
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        // Use ?? '' to handle cases where fields might not exist yet
        _walletAddressController.text = data['walletAddress'] ?? '';
        _twitterController.text = data['twitterHandle'] ?? '';
        _discordController.text = data['discordHandle'] ?? '';
        _telegramController.text = data['telegramHandle'] ?? '';
      }
    } catch (e) {
      log("Error loading user data: $e");
      if (mounted) {
        CustomSnackbar().showCustomSnackbar(
            context, "Could not load profile data.",
            bgColor: Colors.orange);
      }
    } finally {
      // Ensure loading indicator stops even if there's an error
       if (mounted) {
         setState(() => _isLoading = false);
       }
    }
  }


  @override
  void dispose() {
    // Dispose controllers when the widget is removed
    _displayNameController.dispose();
    _walletAddressController.dispose();
    _twitterController.dispose();
    _discordController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  // --- MODIFIED: Save function updated for Firestore ---
  Future<void> _saveProfile() async { // Changed to async
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true); // Show loading indicator

      try {
        // Get the data from controllers
        String displayName = _displayNameController.text.trim();
        String walletAddress = _walletAddressController.text.trim();
        String twitterHandle = _twitterController.text.trim();
        String discordHandle = _discordController.text.trim();
        String telegramHandle = _telegramController.text.trim();

        log('Saving Profile Data:');
        log('Display Name: $displayName');
        log('Wallet Address: $walletAddress');
        log('Twitter: $twitterHandle');
        log('Discord: $discordHandle');
        log('Telegram: $telegramHandle');

        if (widget.currentUser.displayName != displayName) {
          await widget.currentUser.updateDisplayName(displayName);
          log('Firebase Auth Display Name Updated.');
        }

        // 2. Save/Update data in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.currentUser.uid)
            .set({
              'displayName': displayName,
              'walletAddress': walletAddress,
              'twitterHandle': twitterHandle,
              'discordHandle': discordHandle,
              'telegramHandle': telegramHandle,
              'lastUpdated': FieldValue.serverTimestamp(), // Optional: track update time
            }, SetOptions(merge: true)); // merge: true prevents overwriting fields not included here

        log('Firestore User Data Updated.');

        if (mounted) {
          CustomSnackbar().showCustomSnackbar(
              context, "Profile information saved!",
              bgColor: Colors.green);
          Navigator.of(context).pop(); // Go back only on success
        }

      } catch (e) {
         log("Error saving profile data: $e");
         if (mounted) {
           CustomSnackbar().showCustomSnackbar(
              context, "Failed to save profile.",
              bgColor: Colors.red);
         }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false); // Hide loading indicator
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          // Show loading indicator in AppBar or disable button
          if (_isLoading)
             const Padding(
               padding: EdgeInsets.only(right: 16.0),
               child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2,))),
             )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
              tooltip: 'Save Profile',
            ),
        ],
      ),
      // --- ADDED: Show loading overlay ---
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Basic Info",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _displayNameController,
                    enabled: !_isLoading, // Disable fields while loading/saving
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'How you appear in the app',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a display name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Airdrop Info",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your details carefully. These are often required for airdrop participation.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _walletAddressController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Wallet Address (e.g., Ethereum)',
                      hintText: '0x...',
                      prefixIcon: Icon(Icons.wallet_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) { return null; }, // Optional validation
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _twitterController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Twitter Handle',
                      hintText: '@yourhandle',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                     validator: (value) { return null; }, // Optional validation
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _discordController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Discord Handle',
                      hintText: 'username#1234',
                      prefixIcon: Icon(Icons.discord),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                     validator: (value) { return null; }, // Optional validation
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _telegramController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Telegram Handle',
                      hintText: '@yourusername',
                      prefixIcon: Icon(Icons.send_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) { return null; }, // Optional validation
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                      // Disable button while loading/saving
                      onPressed: _isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

