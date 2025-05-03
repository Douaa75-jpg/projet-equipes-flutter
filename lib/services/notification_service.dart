import 'dart:async';


class NotificationService {
  final StreamController<List<Map<String, dynamic>>> _notificationsController = 
      StreamController<List<Map<String, dynamic>>>.broadcast();
  
  List<Map<String, dynamic>> _notifications = [];
  StreamSubscription? _subscription;

  Stream<List<Map<String, dynamic>>> get notifications => _notificationsController.stream;

  void addNotification(Map<String, dynamic> notification) {
    _notifications.insert(0, {
      ...notification,
      'time': DateTime.now().toString(),
      'read': false,
    });
    _notificationsController.add([..._notifications]);
  }

  void markAsRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      _notifications[index]['read'] = true;
      _notificationsController.add([..._notifications]);
    }
  }
  

  void connect(String userId, void Function(String) onNotification) {
    // Simulation de notifications - à remplacer par un vrai service
    _subscription = Stream.periodic(const Duration(seconds: 30)).listen((_) {
      final notification = {
        'title': 'Nouvelle notification',
        'message': 'Mise à jour du système - ${DateTime.now().hour}:${DateTime.now().minute}',
      };
      addNotification(notification);
      onNotification(notification['message'] ?? 'Nouvelle notification'); // Correction ici
    });
  }

  void disconnect() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    disconnect();
    _notificationsController.close();
  }
}