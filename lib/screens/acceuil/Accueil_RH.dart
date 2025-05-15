import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../auth_controller.dart';
import '../../services/notification_service.dart'; // Import ajouté
import '../layoutt/rh_layout.dart';

class AccueilRh extends StatefulWidget {
  const AccueilRh({super.key});

  @override
  State<AccueilRh> createState() => _AccueilRHState();
}

class _AccueilRHState extends State<AccueilRh>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnimation;
  late Animation<double> _textScaleAnimation;
  int _pendingTasks = 5;
  final NotificationService _notificationService =
      NotificationService(); // Déclaration ajoutée

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _logoAnimation = TweenSequence<double>(
      [
        TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 1.1), weight: 1),
        TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.1, end: 1.0), weight: 1),
      ],
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _textScaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.0, end: 1.05), weight: 1),
        TweenSequenceItem<double>(
            tween: Tween<double>(begin: 1.05, end: 1.0), weight: 1),
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
    return RhLayout(
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 600;

          Widget imageSection = Padding(
            padding: const EdgeInsets.all(20),
            child: Image.asset(
              'assets/Top 5.jpg',
              fit: BoxFit.contain,
              width: isWideScreen
                  ? constraints.maxWidth * 0.4
                  : constraints.maxWidth * 0.8,
            ),
          );

          Widget textSection = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isWideScreen)
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
              const SizedBox(height: 6),
              Text(
                'Votre plateforme ',
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
              Text(
                'Transformez votre gestion du personnel',
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
          );

          return NotificationListener<ScrollNotification>(
            onNotification: (scroll) {
              final double offset = scroll.metrics.pixels / 100;
              _controller.animateTo(offset % 1.0);
              return true;
            },
            child: Center(
              child: SingleChildScrollView(
                child: isWideScreen
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          imageSection,
                          const SizedBox(width: 30),
                          Flexible(child: textSection),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          imageSection,
                          const SizedBox(height: 20),
                          textSection,
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
