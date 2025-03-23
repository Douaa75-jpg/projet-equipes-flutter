import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost:3000', // Remplace par l'IP de ton backend
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  );

  Future<Map<String, dynamic>> getPointage(String employeId) async {
    try {
      final response = await _dio.get('/pointage/$employeId');
      return response.data;
    } catch (e) {
      print('Erreur API: $e');
      return {};
    }
  }
}
