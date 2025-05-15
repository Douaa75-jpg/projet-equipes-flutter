import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../auth_controller.dart';
import '../../services/notification_service.dart';
import '../layoutt/employee_layout.dart';

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
  final NotificationService _notificationService = NotificationService();

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
    return EmployeeLayout(
      pendingTasks: _pendingTasks,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWideScreen = constraints.maxWidth > 600;

          Widget imageSection = Padding(
            padding: const EdgeInsets.all(20),
            child: Image.asset(
              'assets/equip3d.PNG',
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
                      height: 100,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'professional_portal'.tr,
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
                'optimize_workflow'.tr,
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

          return Center(
            child: SingleChildScrollView(
              child: isWideScreen
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        textSection,
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
