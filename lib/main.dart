import 'package:flutter/material.dart';
import 'package:crypto_guide/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options:  const FirebaseOptions(
      apiKey: "AIzaSyAQBMLQH-egVqjAlQAgeEGZWoQl1Xa0tds",
      appId: "1:897047020437:android:4f95ef35e83bbe17d5ac9c",
      messagingSenderId: "897047020437",
      projectId: "cryptoguide-2025",
    ),
  );
    runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
