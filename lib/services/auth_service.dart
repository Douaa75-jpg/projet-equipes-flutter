import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Connexion de l'utilisateur
  Future<Map<String, dynamic>> login(String email, String motDePasse) async {
    try {
      Response response = await _dio.post('/auth/login', data: {
        'email': email,
        'motDePasse': motDePasse,
      });

      print("Réponse du serveur: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = response.data;
        print('Données reçues : $data');

        if (data != null && data.containsKey('access_token')) {
          String token = data['access_token'];
          await _storage.write(key: 'jwt_token', value: token);

          // Récupération du rôle directement depuis le JWT
          String role = JwtDecoder.decode(token)['role'];

          // Récupérer typeResponsable seulement si ce n'est pas un employé
          String typeResponsable = '';
          if (role == 'RESPONSABLE') {
            // Si c'est un RESPONSABLE, récupérez le type de responsable
            typeResponsable = data['user']['typeResponsable'] ?? '';
          }

          return {
            'access_token': token,
            'role': role,
            'typeResponsable': typeResponsable,
          };
        } else {
          throw Exception('Jeton d\'accès manquant dans la réponse du backend');
        }
      } else {
        print('Erreur du backend: ${response.data}');
        throw Exception('Erreur backend: ${response.statusCode} - ${response.data}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        print('Erreur du serveur: ${e.response?.data}');
        throw Exception('Échec de la connexion : ${e.response?.data}');
      } else {
        print('Erreur réseau ou serveur inaccessible: ${e.message}');
        throw Exception('Erreur réseau ou serveur inaccessible');
      }
    } catch (e) {
      print('Exception : $e');
      throw Exception('Erreur inattendue : $e');
    }
  }

  // Déconnexion
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    print('Utilisateur déconnecté');
  }

  // Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    String? token = await _storage.read(key: 'jwt_token');
    print('Jeton trouvé : $token');
    return token != null;
  }

  // Vérification du stockage du token
  Future<void> verifyTokenStorage() async {
    try {
      String? storedToken = await _storage.read(key: 'jwt_token');
      print('Le token stocké: $storedToken');

      if (storedToken != null) {
        print('Le token est présent!');
      } else {
        print('Le token n\'est pas présent!');
      }
    } catch (e) {
      print('Erreur lors de la lecture du token: $e');
    }
  }

  // Fonction pour utiliser le token stocké avec Dio
  Future<void> useTokenWithApi() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');

      if (token != null) {
        final dio = Dio();
        dio.options.headers = {
          'Authorization': 'Bearer $token',
        };

        // Exemple d'appel API avec le token
        final response = await dio.get('http://localhost:3000/auth/login');
        if (response.statusCode == 200) {
          print('Réponse de l\'API avec le token: ${response.data}');
        } else {
          print('Erreur API: ${response.statusCode}');
        }
      } else {
        print('Le token n\'est pas disponible!');
      }
    } catch (e) {
      print('Erreur d\'appel API avec le token: $e');
    }
  }

  // Fonction pour supprimer le token
  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: 'jwt_token');
      print('Le token a été supprimé');
    } catch (e) {
      print('Erreur lors de la suppression du token: $e');
    }
  }
}
