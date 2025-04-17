import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart'; // Make sure to include this dependency

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _role;
  String? _typeResponsable;
  String? _userId;
  String? _nom; // إضافة حقل الاسم
  String? _prenom;
  String? _email;
  String? _matricule;
  String? _datedenaissance;
  bool _isAuthenticated = false;
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  String? get token => _token;
  String? get role => _role;
  String? get typeResponsable => _typeResponsable;
  String? get nom => _nom; // توفير الـ getter لاسم المستخدم
  String? get prenom => _prenom;
  String? get email => _email;
  String? get matricule => _matricule;
  String? get datedenaissance => _datedenaissance;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;

  // Method to login the user
  Future<Map<String, dynamic>> login(String email, String motDePasse) async {
    final url = Uri.parse('http://localhost:3000/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'motDePasse': motDePasse}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = json.decode(response.body);
      _token = responseData['access_token'];
      _role = responseData['user']['role'];
      _typeResponsable = responseData['user']['typeResponsable'];
      _userId = responseData['user']['id'];
      _nom = responseData['user']['nom']; // استخراج الاسم من الاستجابة
      _prenom = responseData['user']['prenom'];
      _email = responseData['user']['email'];
      _matricule = responseData['user']['matricule'];
      _datedenaissance = responseData['user']['datedenaissance'];
      _isAuthenticated = true;

      // Store token securely
      await _storage.write(key: 'jwt_token', value: _token);

      notifyListeners();

      return {'role': _role, 'typeResponsable': _typeResponsable ?? ''};
    } else {
      throw Exception('Erreur serveur : ${response.statusCode}');
    }
  }

  // Method to logout the user
  Future<void> logout() async {
    _token = null;
    _role = null;
    _typeResponsable = null;
    _userId = null;
    _nom = null; 
    _prenom = null;
    _email = null;
    _matricule = null;
    _datedenaissance = null;
    _isAuthenticated = false;

    // Remove token from secure storage
    await _storage.delete(key: 'jwt_token');

    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    String? token = await _storage.read(key: 'jwt_token');

    if (token == null || JwtDecoder.isExpired(token)) {
      return null;
    }

    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

    // تحديث البيانات داخل AuthProvider
    _userId = decodedToken['id'];
    _role = decodedToken['role'];
    _typeResponsable = decodedToken['typeResponsable'];
    _nom = decodedToken['nom']; // استخراج الاسم من الـ JWT
    _prenom = decodedToken['prenom'];
    _email = decodedToken['email'];
    _matricule = decodedToken['matricule'];
    _datedenaissance = decodedToken['datedenaissance'];
    notifyListeners();

      return {
    'id': _userId,
    'email': _email,
    'role': _role,
    'typeResponsable': _typeResponsable,
    'nom': _nom,
    'prenom': _prenom,
    'matricule': _matricule,
    'datedenaissance': _datedenaissance,
  };

  }
}
