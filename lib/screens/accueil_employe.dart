import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart'; 
import '../AuthProvider.dart';
import '../services/notification_service.dart'; // Import ajouté
import 'employee_layout.dart';



class AccueilEmploye extends StatefulWidget {
  const AccueilEmploye({super.key});

  @override
  State<AccueilEmploye> createState() => _AccueilEmployeState();
}

class _AccueilEmployeState extends State<AccueilEmploye> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _textScaleAnimation;
  int _pendingTasks = 5;
  final NotificationService _notificationService = NotificationService(); // Déclaration ajoutée


  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _logoAnimation = TweenSequence<double>(
      [
        TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 1.1), weight: 1),
        TweenSequenceItem<double>(tween: Tween<double>(begin: 1.1, end: 1.0), weight: 1),
      ],
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _textScaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 1.05), weight: 1),
        TweenSequenceItem<double>(tween: Tween<double>(begin: 1.05, end: 1.0), weight: 1),
      ],
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EmployeeLayout(
      pendingTasks: _pendingTasks,
       notificationService: _notificationService,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          final double offset = scroll.metrics.pixels / 100;
          _controller.animateTo(offset % 1.0);
          return true;
        },
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoAnimation.value,
                      child: Image.asset(
                        'assets/logo.png',
                        height: 150,
                        width: 150,
                        fit: BoxFit.contain,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                Column(
                  children: [
                    Text(
                      'Votre portail professionnel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        color: const Color.fromARGB(255, 32, 32, 59),
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black.withAlpha(51),
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Optimisez votre workflow avec ZetaBox',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        color: const Color.fromARGB(255, 32, 32, 59),
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black.withAlpha(51),
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _textScaleAnimation.value,
                      child: Text(
                        'Votre efficacité, notre priorité',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 195, 26, 26),
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.black.withAlpha(51),
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                _buildLottieAnimation(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLottieAnimation() {
    try {
      return Lottie.asset(
        'assets/equipe.json',
        width: 300,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, color: Colors.red, size: 50);
        },
      );
    } catch (e) {
      return const Icon(Icons.error, color: Colors.red, size: 50);
    }
  }
}