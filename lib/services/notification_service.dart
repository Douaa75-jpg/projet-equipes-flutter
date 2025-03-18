import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationService {
  late IO.Socket socket;

  // تهيئة الاتصال بالـ WebSocket
  void initializeSocket(String responsableId) {
    socket = IO.io('http://localhost:3000', IO.OptionBuilder()
        .setTransports(['websocket']) // استخدام WebSocket فقط
        .build());

    // الاتصال بـ WebSocket
    socket.connect();

    // الاستماع للـ Notification الخاصة بالـ Responsable
    socket.on('notification_$responsableId', (data) {
      print('Notification: ${data['message']}');
      // هنا تقدر تعرض الـ Notification في التطبيق
      // مثلا: باستخدام AlertDialog أو Snackbar أو أي واجهة مستخدم تفضلها
    });
  }

  // إغلاق الاتصال بالـ WebSocket
  void disconnectSocket() {
    socket.disconnect();
  }
}
