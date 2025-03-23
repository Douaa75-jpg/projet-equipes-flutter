import 'package:flutter/material.dart';

class RHDashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard - RH')),
      body: Center(
        child: Column(
          children: [
            Text('مرحبا بيك RH!'),
            ElevatedButton(
              onPressed: () {},
              child: Text('إدارة الكونجي'),
            ),
            ElevatedButton(
              onPressed: () {},
              child: Text('معاينة بيانات الموظفين'),
            ),
          ],
        ),
      ),
    );
  }
}
