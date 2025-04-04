import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الإشعارات'),
      ),
      body: ListView.builder(
        itemCount: 10, // استبدل بـ البيانات الفعلية للإشعارات
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('إشعار #$index'),
            subtitle: Text('تفاصيل الإشعار رقم $index'),
            onTap: () {
              // عند الضغط على الإشعار يمكنك إضافة وظيفة معينة هنا
            },
          );
        },
      ),
    );
  }
}
