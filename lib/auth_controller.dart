import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends GetxController {
  final RxString token = ''.obs;
  final RxString role = ''.obs;
  final RxString typeResponsable = ''.obs;
  final RxString userId = ''.obs;
  final RxString nom = ''.obs;
  final RxString prenom = ''.obs;
  final RxString email = ''.obs;
  final RxString matricule = ''.obs;
  final RxString datedenaissance = ''.obs;
  final RxBool isAuthenticated = false.obs;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

   @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

   Future<void> checkAuthStatus() async {
  try {
    final storedToken = await _storage.read(key: 'jwt_token');
    debugPrint('Retrieved token from storage: $storedToken');
    
    if (storedToken == null || storedToken.isEmpty) {
      debugPrint('No token found in storage');
      isAuthenticated.value = false;
      return;
    }

    if (JwtDecoder.isExpired(storedToken)) {
      debugPrint('Token is expired');
      await logout();
      return;
    }

    token.value = storedToken;
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(storedToken);
    
    if (decodedToken['id'] == null) {
      throw Exception('Invalid token: missing user ID');
    }

    userId.value = decodedToken['id'].toString();
    // Store the user ID in secure storage
    await _storage.write(key: 'user_id', value: userId.value); // Add this line
    
    nom.value = decodedToken['nom']?.toString() ?? '';
    prenom.value = decodedToken['prenom']?.toString() ?? '';
    email.value = decodedToken['email']?.toString() ?? '';
    role.value = decodedToken['role']?.toString() ?? '';
    typeResponsable.value = decodedToken['typeResponsable']?.toString() ?? '';
    matricule.value = decodedToken['matricule']?.toString() ?? '';
    datedenaissance.value = decodedToken['datedenaissance']?.toString() ?? '';
    isAuthenticated.value = true;

    debugPrint('User authenticated successfully: ${email.value}');
  } catch (e) {
    debugPrint('Error in checkAuthStatus: $e');
    isAuthenticated.value = false;
  }
}

  Future<Map<String, dynamic>> login(String email, String motDePasse) async {
    final url = Uri.parse('http://localhost:3000/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'motDePasse': motDePasse}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      token.value = responseData['access_token'];
      role.value = responseData['user']['role'];
      typeResponsable.value = responseData['user']['typeResponsable'] ?? '';
      userId.value = responseData['user']['id'];
      nom.value = responseData['user']['nom'] ?? '';
      prenom.value = responseData['user']['prenom'] ?? '';
      this.email.value = responseData['user']['email'] ?? '';
      matricule.value = responseData['user']['matricule'] ?? '';
      datedenaissance.value = responseData['user']['datedenaissance'] ?? '';
      isAuthenticated.value = true;

      await _storage.write(key: 'jwt_token', value: token.value);
      await _storage.write(key: 'user_id', value: userId.value);

      return {
        'role': role.value,
        'typeResponsable': typeResponsable.value,
      };
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  Future<void> logout() async {
    token.value = '';
    role.value = '';
    typeResponsable.value = '';
    userId.value = '';
    nom.value = '';
    prenom.value = '';
    email.value = '';
    matricule.value = '';
    datedenaissance.value = '';
    isAuthenticated.value = false;

    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_id');
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final storedToken = token.value.isNotEmpty ? token.value : await _storage.read(key: 'jwt_token');

    if (storedToken == null || storedToken.isEmpty || JwtDecoder.isExpired(storedToken)) {
      return null;
    }

    token.value = storedToken;
    final Map<String, dynamic> decodedToken = JwtDecoder.decode(storedToken);

    userId.value = decodedToken['id'];
    role.value = decodedToken['role'];
    typeResponsable.value = decodedToken['typeResponsable'] ?? '';
    nom.value = decodedToken['nom'] ?? '';
    prenom.value = decodedToken['prenom'] ?? '';
    email.value = decodedToken['email'] ?? '';
    matricule.value = decodedToken['matricule'] ?? '';
    datedenaissance.value = decodedToken['datedenaissance'] ?? '';
    isAuthenticated.value = true;

    return {
      'id': userId.value,
      'email': email.value,
      'role': role.value,
      'typeResponsable': typeResponsable.value,
      'nom': nom.value,
      'prenom': prenom.value,
      'matricule': matricule.value,
      'datedenaissance': datedenaissance.value,
    };
  }
}
