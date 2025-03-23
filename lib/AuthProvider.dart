import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _employeeId;
  String? _role;

  String? get token => _token;
  String? get employeeId => _employeeId;
  String? get role => _role;

  // تعيين التوكن والمعرف
  void setAuthData(String? token, String? employeeId, String? role) {
  _token = token ?? ''; // Assurer que _token n'est jamais null
  _employeeId = employeeId ?? ''; // Idem pour _employeeId
  _role = role ?? ''; // Idem pour _role
  notifyListeners();
}


  // حذف بيانات التوثيق عند تسجيل الخروج
  void clearAuthData() {
    _token = null;
    _employeeId = null;
    _role = null;
    notifyListeners();
  }

  // التحقق من وجود التوكن
  bool get isAuthenticated => _token != null;
}
