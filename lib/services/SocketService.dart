import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect() {
    socket = IO.io('http://localhost:3000', IO.OptionBuilder()
        .setTransports(['websocket']) // specify the transport method
        .build());

    socket.onConnect((_) {
      print('connected to WebSocket');
    });

    // Listen to the notification event
    socket.on('notification', (data) {
      print('New notification: $data');
      // هنا تعمل أي حاجة لتعرض الرسالة للمستخدم (مثلا عبر توست أو pop-up)
    });

    socket.onDisconnect((_) {
      print('disconnected from WebSocket');
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}
