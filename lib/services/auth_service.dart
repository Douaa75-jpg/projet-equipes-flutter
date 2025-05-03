import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/auth'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String email, String motDePasse) async {
    try {
      Response response = await _dio.post('/login', data: {
        'email': email,
        'motDePasse': motDePasse,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = response.data;
        if (data != null && data.containsKey('access_token')) {
          String token = data['access_token'];

          if (JwtDecoder.isExpired(token)) {
            throw Exception('Le token a expiré. Veuillez vous reconnecter.');
          }

          await _storage.write(key: 'jwt_token', value: token);

          String role = JwtDecoder.decode(token)['role'];
          String typeResponsable = role == 'RESPONSABLE' ? data['user']['typeResponsable'] ?? '' : '';
          String nom = data['user']['nom'] ?? '';

          return {
            'access_token': token,
            'role': role,
            'typeResponsable': typeResponsable,
            'nom': nom,
          };
        } else {
          throw Exception('Jeton d\'accès manquant dans la réponse du backend');
        }
      } else {
        throw Exception('Erreur backend: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Erreur de connexion: $e');
      throw Exception('Erreur de connexion: ${e.message}');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/forgot-password',
        data: {'email': email},
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Échec de l\'envoi du lien de réinitialisation');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur de connexion');
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await _dio.post(
        '/reset-password',
        data: {
          'token': token,
          'newPassword': newPassword,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Échec de la réinitialisation');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur de connexion');
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token == null || JwtDecoder.isExpired(token)) return null;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
    String nom = decodedToken['nom'] ?? ''; 
    return {
      'id': decodedToken['id'],
      'email': decodedToken['email'],
      'role': decodedToken['role'],
      'typeResponsable': decodedToken['typeResponsable'],
      'nom': nom,
    };
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> isLoggedIn() async {
    String? token = await _storage.read(key: 'jwt_token');
    return token != null && !JwtDecoder.isExpired(token);
  }

  Future<void> verifyTokenStorage() async {
    try {
      String? storedToken = await _storage.read(key: 'jwt_token');
      print('Le token stocké: $storedToken');

      if (storedToken != null) {
        if (JwtDecoder.isExpired(storedToken)) {
          print('Le token est expiré');
          await _storage.delete(key: 'jwt_token');
        } else {
          print('Le token est valide');
        }
      } else {
        print('Le token n\'est pas présent!');
      }
    } catch (e) {
      print('Erreur lors de la lecture du token: $e');
    }
  }
}