import 'package:dio/dio.dart' as dio;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthService extends GetxController {
  final dio.Dio _dio = dio.Dio(dio.BaseOptions(baseUrl: 'http://localhost:3000/auth'));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final RxString token = ''.obs;
  final RxString role = ''.obs;
  final RxString typeResponsable = ''.obs;
  final RxString nom = ''.obs;

  @override
  void onInit() {
    super.onInit();
    verifyTokenStorage();
  }

  Future<Map<String, dynamic>> login(String email, String motDePasse) async {
    try {
      dio.Response response = await _dio.post('/login', data: {
        'email': email,
        'motDePasse': motDePasse,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        var data = response.data;
        if (data != null && data.containsKey('access_token')) {
          String newToken = data['access_token'];

          if (JwtDecoder.isExpired(newToken)) {
            throw Exception('Le token a expiré. Veuillez vous reconnecter.');
          }

          token.value = newToken;
          await _storage.write(key: 'jwt_token', value: newToken);
          
          await _storage.write(key: 'user_role', value: data['user']['role']);
          await _storage.write(key: 'user_typeResponsable', value: data['user']['typeResponsable'] ?? '');
          await _storage.write(key: 'user_nom', value: data['user']['nom'] ?? '');

          role.value = data['user']['role'];
          typeResponsable.value = role.value == 'RESPONSABLE' 
              ? data['user']['typeResponsable'] ?? ''
              : '';
          nom.value = data['user']['nom'] ?? '';

          return {
            'access_token': newToken,
            'role': role.value,
            'typeResponsable': typeResponsable.value,
            'nom': nom.value,
          };
        } else {
          throw Exception('Jeton d\'accès manquant dans la réponse du backend');
        }
      } else {
        throw Exception('Erreur backend: ${response.statusCode}');
      }
    } on dio.DioException catch (e) {
      if (e.response?.statusCode == 401) {
        if (e.response?.data['message']?.toString().toLowerCase().contains('email') ?? false) {
          throw Exception('Email incorrect');
        } else if (e.response?.data['message']?.toString().toLowerCase().contains('mot de passe') ?? false) {
          throw Exception('Mot de passe incorrect');
        } else {
          throw Exception('Email ou mot de passe incorrect');
        }
      } else if (e.type == dio.DioExceptionType.connectionTimeout ||
                 e.type == dio.DioExceptionType.receiveTimeout) {
        throw Exception('Timeout de connexion');
      } else {
        throw Exception('Erreur de connexion: ${e.message}');
      }
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '/forgot-password',
        data: {'email': email},
        options: dio.Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Échec de l\'envoi du lien de réinitialisation');
      }
    } on dio.DioException catch (e) {
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
        options: dio.Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Échec de la réinitialisation');
      }
    } on dio.DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur de connexion');
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    String? storedToken = await _storage.read(key: 'jwt_token');
    if (storedToken == null || JwtDecoder.isExpired(storedToken)) return null;

    Map<String, dynamic> decodedToken = JwtDecoder.decode(storedToken);
    nom.value = decodedToken['nom'] ?? '';
    return {
      'id': decodedToken['id'],
      'email': decodedToken['email'],
      'role': decodedToken['role'],
      'typeResponsable': decodedToken['typeResponsable'],
      'nom': nom.value,
    };
  }

  Future<void> logout() async {
    try {
      token.value = '';
      role.value = '';
      typeResponsable.value = '';
      nom.value = '';
      
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'user_role');
      await _storage.delete(key: 'user_typeResponsable');
      await _storage.delete(key: 'user_nom');
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    String? storedToken = await _storage.read(key: 'jwt_token');
    return storedToken != null && !JwtDecoder.isExpired(storedToken);
  }

  Future<void> verifyTokenStorage() async {
    try {
      String? storedToken = await _storage.read(key: 'jwt_token');
      print('Le token stocké: $storedToken');

      if (storedToken != null && storedToken.isNotEmpty) {
        if (JwtDecoder.isExpired(storedToken)) {
          print('Le token est expiré');
          await logout();
        } else {
          print('Le token est valide');
          token.value = storedToken;
          
          role.value = await _storage.read(key: 'user_role') ?? '';
          typeResponsable.value = await _storage.read(key: 'user_typeResponsable') ?? '';
          nom.value = await _storage.read(key: 'user_nom') ?? '';
        }
      } else {
        print('Aucun token trouvé dans le stockage');
      }
     } catch (e) {
      print('Erreur lors de la lecture du token: $e');
      await logout();
    }
  }
}