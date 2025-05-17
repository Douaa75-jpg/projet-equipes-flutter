import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth/login_screen.dart';
import 'auth/registre_screen.dart';

class ChoiceScreen extends StatefulWidget {
  const ChoiceScreen({super.key});

  @override
  State<ChoiceScreen> createState() => _ChoiceScreenState();
}

class _ChoiceScreenState extends State<ChoiceScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _shakeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animation for fade and slide
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Shake animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
        TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
      ],
    ).animate(_shakeController);

    // Start shake animation after slide/fade completes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;
    final isSmallMobile = MediaQuery.of(context).size.width < 350;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFEBEE), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeAnimation.value, 0),
                    child: child,
                  );
                },
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 48 : 24,
                      vertical: isDesktop ? 64 : 32,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 600 : double.infinity,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo
                          Hero(
                            tag: "app_logo",
                            child: Image.asset(
                              'assets/logo.png',
                              width: isDesktop ? 180 : 120,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 40 : 30),

                          // Titre
                          Text(
                            "Construire l'avenir des",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 42 : 34,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2F3A4C),
                              shadows: const [
                                Shadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 1))
                              ],
                            ),
                          ),
                          Text(
                            "Solutions logicielles",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 46 : 38,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD32F2F),
                            ),
                          ),
                          SizedBox(height: isDesktop ? 30 : 20),

                          // Sous-titre
                          Text(
                            "Nous vous souhaitons une agréable expérience avec nous.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 20 : 18,
                              fontStyle: FontStyle.italic,
                              color: Colors.black54,
                            ),
                          ),
                          SizedBox(height: isDesktop ? 60 : 50),

                          // Boutons - version responsive
                          if (isDesktop)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLoginButton(isSmallMobile, context),
                                const SizedBox(width: 20),
                                _buildRegisterButton(isSmallMobile, context),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _buildLoginButton(isSmallMobile, context),
                                const SizedBox(height: 20),
                                _buildRegisterButton(isSmallMobile, context),
                              ],
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isSmallMobile, BuildContext context) {
    return SizedBox(
      width: isSmallMobile ? double.infinity : 250,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) =>  LoginScreen()),
          );
        },
        icon: const Icon(Icons.login),
        label: Text(
          "Se connecter",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }

  Widget _buildRegisterButton(bool isSmallMobile, BuildContext context) {
    return SizedBox(
      width: isSmallMobile ? double.infinity : 250,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) =>  RegisterPage()),
          );
        },
        icon: const Icon(Icons.person_add, color: Color(0xFFD32F2F)),
        label: Text(
          "Créer un compte",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFD32F2F),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }
}