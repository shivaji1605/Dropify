import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// --- MODIFIED: Import the two new Nav screens ---
import 'package:crypto_guide/user_nav_screen.dart'; // User's 4-tab app
import 'package:crypto_guide/admin_nav_screen.dart'; // Admin's 4-tab app
import 'package:crypto_guide/login_screen.dart'; // Fallback
import 'dart:developer';

class DecisionScreen extends StatefulWidget {
  const DecisionScreen({super.key});

  @override
  State<DecisionScreen> createState() => _DecisionScreenState();
}

class _DecisionScreenState extends State<DecisionScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserRoleAndNavigate();
  }

  Future<void> _checkUserRoleAndNavigate() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      log("DecisionScreen: No user found, redirecting to Login.");
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
      return;
    }

    try {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        
        if (data['isAdmin'] == true) {
          // --- ADMIN ---
          log("DecisionScreen: Admin user detected. Redirecting to AdminNavScreen.");
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              // --- CHANGE: Go to AdminNavScreen ---
              MaterialPageRoute(builder: (context) => const AdminNavScreen()),
              (Route<dynamic> route) => false,
            );
          }
        } else {
          // --- REGULAR USER ---
          log("DecisionScreen: Regular user detected. Redirecting to UserNavScreen.");
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              // --- CHANGE: Go to UserNavScreen ---
              MaterialPageRoute(builder: (context) => const UserNavScreen()),
              (Route<dynamic> route) => false,
            );
          }
        }
      } else {
        // --- REGULAR USER (Document doesn't exist) ---
        log("DecisionScreen: User document not found. Defaulting to UserNavScreen.");
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            // --- CHANGE: Go to UserNavScreen ---
            MaterialPageRoute(builder: (context) => const UserNavScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      // --- ERROR (Default to regular user) ---
      log("DecisionScreen: Error checking role: $e. Defaulting to UserNavScreen.");
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          // --- CHANGE: Go to UserNavScreen ---
          MaterialPageRoute(builder: (context) => const UserNavScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
