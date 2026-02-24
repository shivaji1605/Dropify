import 'package:crypto_guide/decision_screen.dart';
import 'package:crypto_guide/signin_screen.dart';
import 'package:flutter/material.dart';
// --- RE-ADDED: google_fonts import ---
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer';
import 'custom_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _isPasswordVisible = false;
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      log("Google Sign-In Successful: ${userCredential.user?.displayName}");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (mounted) {
        CustomSnackbar().showCustomSnackbar(
          context,
          "Login Successful!",
          bgColor: Colors.green,
        );
        navigateToHome(context); // <-- This function is now updated
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        CustomSnackbar().showCustomSnackbar(
            context, e.message ?? "An error occurred",
            bgColor: Colors.red);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar().showCustomSnackbar(
            context, "Failed to sign in with Google.",
            bgColor: Colors.red);
      }
    }
  }

  void navigateToSignin(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return const SigninScreen();
    }));
  }

  // --- THIS FUNCTION IS MODIFIED ---
  void navigateToHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      // --- CHANGE: Go to DecisionScreen, NOT NavScreen ---
      MaterialPageRoute(builder: (context) => const DecisionScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Image.asset('assets/images/airdropLogo12.png', height: 150),
              const SizedBox(height: 20),
              Text(
                "Welcome Back!",
                // --- MODIFIED: Use GoogleFonts package ---
                style: GoogleFonts.quicksand(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.mail),
                    hintText: "Email Address",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    )),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    hintText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    )),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20))),
                onPressed: () async {
                  if (emailController.text.trim().isNotEmpty &&
                      passwordController.text.trim().isNotEmpty) {
                    try {
                      UserCredential userCredentialObj = await _firebaseAuth
                          .signInWithEmailAndPassword(
                              email: emailController.text.trim(),
                              password: passwordController.text.trim());

                      // Save login state
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('isLoggedIn', true);

                      if (mounted) {
                        CustomSnackbar().showCustomSnackbar(
                            context, "Login Successful!",
                            bgColor: Colors.green);

                        log("User:$userCredentialObj");
                        emailController.clear();
                        passwordController.clear();
                        navigateToHome(context); // <-- This function is now updated
                      }
                    } on FirebaseAuthException catch (error) {
                      if (mounted) {
                        CustomSnackbar().showCustomSnackbar(
                            context, error.message!,
                            bgColor: Colors.red);
                      }
                    }
                  } else {
                    CustomSnackbar().showCustomSnackbar(
                        context, "Please enter all fields!",
                        bgColor: Colors.red);
                  }
                },
                child: const Text("Login", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 40),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: Colors.grey.shade300)),
                onPressed: _signInWithGoogle,
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  height: 24.0,
                ),
                label: const Text(
                  "Continue with Google",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
              const SizedBox(height: 30),
              TextButton(
                onPressed: () {
                  navigateToSignin(context);
                },
                child: Text(
                  "New user? Sign Up",
                  // --- MODIFIED: Use GoogleFonts package ---
                  style: GoogleFonts.quicksand(
                    fontSize: 16, 
                    color: Colors.blue
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

