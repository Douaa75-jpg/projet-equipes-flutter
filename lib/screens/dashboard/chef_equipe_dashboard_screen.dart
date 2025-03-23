import 'package:flutter/material.dart';

class ChefEquipeDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard - Chef d\'équipe')),
      body: Center(
        child: Column(
          children: [
            Text('مرحبا بيك Chef d\'équipe!'),
            ElevatedButton(
              onPressed: () {},
              child: Text('إسناد المهام'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('متابعة أداء الفريق'),
            ),
          ],
        ),
      ),
    );
  }
}
