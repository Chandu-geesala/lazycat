import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import '../login.dart';
import 'intro.dart';

class MysplashScreen extends StatefulWidget {
  const MysplashScreen({super.key});

  @override
  State<MysplashScreen> createState() => _MysplashScreenState();
}

class _MysplashScreenState extends State<MysplashScreen> {
  @override
  void initState() {
    super.initState();
    initTimer();
  }

  void initTimer() async {
    Timer(const Duration(seconds: 2), () async {
      // Check if the intro has been completed
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isIntroCompleted = prefs.getBool('isIntroCompleted') ?? false;

      // Check if the user is logged in
      User? user = FirebaseAuth.instance.currentUser;

      if (isIntroCompleted) {
        if (user == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the current brightness mode from the system
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      // Apply background color based on theme
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Center(
        child: Image.asset(
          // Use different logo assets for light and dark mode if needed
         'assets/l.png',
          // If you use the same logo for both modes, just keep the original line:
          // 'assets/l.png',
        ),
      ),
    );
  }
}