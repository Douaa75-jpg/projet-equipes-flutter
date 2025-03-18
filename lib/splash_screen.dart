import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home/home_page.dart';
import 'choice_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    final isAuthenticated = await _checkAuthentication();

    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isAuthenticated ? HomeScreen() : const ChoiceScreen(),
        ),
      );
    });
  }

  Future<bool> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isAuthenticated') ?? false; // Remplacer par la logique appropriée
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/zeta.png', // Assurez-vous que l'image est bien déclarée dans pubspec.yaml
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}
