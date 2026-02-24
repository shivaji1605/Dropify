import 'package:crypto_guide/login_screen.dart';
import 'package:crypto_guide/decision_screen.dart';
import 'package:flutter/material.dart';
// --- RE-ADDED: google_fonts import ---
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer';
import 'package:crypto_guide/custom_snackbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
// --- REMOVED: Unused nav_screen import ---
// import 'package:crypto_guide/nav_screen.dart'; 


class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});
  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _isPasswordVisible = false;
  }
  
  // --- MODIFIED: Google Sign-In Logic ---
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; 
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      log("Google Sign-In Successful: ${userCredential.user?.displayName}");

      //Save login state ---
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      if (mounted) {
        CustomSnackbar().showCustomSnackbar(
          context,
          "Login Successful!",
          bgColor: Colors.green,
        );
        
        // --- MODIFIED: Navigate to DecisionScreen ---
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const DecisionScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        CustomSnackbar().showCustomSnackbar(context, e.message ?? "An error occurred", bgColor: Colors.red);
      }
    } catch (e) {
      log("Google Sign-In Error: $e"); 
      if (mounted) {
        CustomSnackbar().showCustomSnackbar(context, "Failed to sign in with Google.", bgColor: Colors.red);
      }
    }
  }

  void navigateToLogin(BuildContext context) {
    if(Navigator.canPop(context)){
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
        return const LoginScreen();
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => navigateToLogin(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Text(
                "Create Account",
                // --- MODIFIED: Use GoogleFonts package ---
                style: GoogleFonts.quicksand(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "Enter the crypto world with us",
                // --- MODIFIED: Use GoogleFonts package ---
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  color: Colors.grey[600]
                ),
              ),
              const SizedBox(height: 50),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
                ),
                onPressed: () async {
                  if (emailController.text.trim().isNotEmpty &&
                      passwordController.text.trim().isNotEmpty) {
                    try {
                      await _firebaseAuth
                          .createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );

                      if(mounted) {
                        CustomSnackbar().showCustomSnackbar(
                          context,
                          "User Registered Successfully! Please log in.",
                          bgColor: Colors.green,
                        );
                        // Go back to the login screen after successful registration
                        navigateToLogin(context);
                      }
                    } on FirebaseAuthException catch (error) {
                      if(mounted) {
                        CustomSnackbar().showCustomSnackbar(
                          context,
                          error.message!,
                          bgColor: Colors.red,
                        );
                      }
                    }
                  } else {
                    CustomSnackbar().showCustomSnackbar(
                      context,
                      "Please enter all fields!",
                      bgColor: Colors.red,
                    );
                  }
                },
                child: const Text("Sign Up", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 30),
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
              const SizedBox(height: 60),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  side: BorderSide(color: Colors.grey.shade300)
                ),
                onPressed: _signInWithGoogle,
                icon: Image.asset('assets/images/google_logo.png', height: 24.0,),
                label: const Text(
                  "Continue with Google",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

