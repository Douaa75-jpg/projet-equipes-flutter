import 'package:socket_io_client/socket_io_client.dart' as IO;

class NotificationService {
  late IO.Socket _socket;

  // Connexion à WebSocket avec l'ID de l'utilisateur
  void connect(String userId, Function(String) onNotificationReceived) {
    // Crée la connexion WebSocket en définissant les options nécessaires
    _socket = IO.io(
      'http://localhost:3000', // Remplacez par l'URL de votre serveur Socket.IO
      IO.OptionBuilder()
          .setTransports(['websocket']) // Utilise uniquement WebSocket
          .disableAutoConnect() // Connexion manuelle
          .setQuery({'userId': userId}) // Ajoute l'ID de l'utilisateur à la requête
          .build(),
    );

    // Connexion au serveur
    _socket.connect();

    // Lorsque la connexion est établie
    _socket.onConnect((_) {
      print('✅ Employé connecté au WebSocket');
    });

    // Réception des notifications
    _socket.on('notification', (data) {
      print('🔔 Notification reçue : $data');
      onNotificationReceived(data); // Appel du callback pour traiter la notification reçue
    });

    // Gestion de la déconnexion
    _socket.onDisconnect((_) {
      print('❌ Déconnecté du WebSocket');
    });

    // Gestion des erreurs de connexion
    _socket.onError((error) {
      print('❌ Erreur WebSocket : $error');
    });
  }

  // Déconnexion du serveur WebSocket
  void disconnect() {
    _socket.disconnect();
    print('❌ Déconnecté du WebSocket');
  }

  // Envoi d'une notification via WebSocket
  void sendNotification(String userId, String message) {
    // Envoie un événement de notification avec l'ID de l'utilisateur et le message
    _socket.emit('notification', {'userId': userId, 'message': message});
    print('📤 Notification envoyée à $userId: $message');
  }
}
