import 'package:flutter/material.dart';
import 'package:crypto_guide/login_screen.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
// --- MODIFIED: Import the decision screen ---
import 'package:crypto_guide/decision_screen.dart'; 


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();
    navigate(context);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  void navigate(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (context.mounted) {
        if (isLoggedIn) {
          // --- THIS IS THE CHANGE ---
          // Navigate to the DecisionScreen to check for admin/user
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DecisionScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF8FAFF),
              Color(0xFFF2F6FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 180,
              left: MediaQuery.of(context).size.width / 2 - 100,
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                height: _isVisible ? 200 : 150,
                width: _isVisible ? 200 : 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.2),
                      blurRadius: 80,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
            ),

            AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeIn,
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Hero(
                        tag: "app_logo",
                        child: Image.asset(
                          'assets/images/airdropLogo12.png',
                          height: 300,
                          width: 300,
                        ),
                      ),
                      const SizedBox(height: 30),

                      Text(
                        "Dropify",
                        // --- MODIFIED: Use GoogleFonts package ---
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Text(
                        "Your Smart Crypto Companion",
                        // --- MODIFIED: Use GoogleFonts package ---
                        style: GoogleFonts.quicksand(
                          fontSize: 15,
                          color: Colors.blueGrey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            AnimatedOpacity(
              opacity: _isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeIn,
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "by DevDroids",
                    // --- MODIFIED: Use GoogleFonts package ---
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

