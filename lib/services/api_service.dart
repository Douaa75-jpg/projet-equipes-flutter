import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final _storage = FlutterSecureStorage();
  final String _baseUrl = 'http://localhost:3000/auth';  // Remplace par l'URL de ton backend

  // Fonction pour se connecter
  Future<bool> login(String email, String motDePasse) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': email,
        'motDePasse': motDePasse,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final token = responseData['access_token'];

      if (token != null) {
        await _storage.write(key: 'jwt_token', value: token);  // Stockage du token
        return true;
      }
    }
    return false;
  }

  // Récupérer le token JWT stocké
  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Fonction pour vérifier si l'utilisateur est connecté en vérifiant le token
  Future<bool> isAuthenticated() async {
    String? token = await getToken();
    return token != null;
  }

  // Fonction pour se déconnecter
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');  // Supprimer le token lors de la déconnexion
  }
}
