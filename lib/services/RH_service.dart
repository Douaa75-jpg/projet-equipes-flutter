import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class RhService extends GetxService {
  final String baseUrl = 'http://localhost:3000/utilisateurs';
  final String baseUrlEmployes = 'http://localhost:3000/employes';
  final String baseUrlResponsables = 'http://localhost:3000/responsables';

  // Reactive variables
  final RxList<Employe> employees = <Employe>[].obs;
  final RxList<Responsable> responsables = <Responsable>[].obs;
  final RxInt employesCount = 0.obs;
  final RxInt responsablesCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize data when service is created
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    await getEmployesCount();
    await getResponsablesCount();
    await getEmployees();
    await getResponsables();
  }

  // Get employees count (reactive)
  Future<int> getEmployesCount() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/count/employes'))
      .timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      employesCount.value = data['totalEmployes'] ?? 0;
      return employesCount.value;
    } else {
      throw Exception('Failed to load employees count: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error in getEmployesCount: $e');
    Get.snackbar('Error', 'Failed to fetch employees count');
    return 0; // Return default value
  }
}

  // Get responsables count (reactive)
  Future<int> getResponsablesCount() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/count/responsables'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        responsablesCount.value = data['totalResponsables'];
        return responsablesCount.value;
      } else {
        throw Exception('Failed to load responsables count');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch responsables count: $e');
      rethrow;
    }
  }

  // Get all responsables (reactive)
  Future<List<Responsable>> getResponsables() async {
    try {
      final response = await http.get(Uri.parse(baseUrlResponsables));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        responsables.assignAll(data.map((item) => Responsable.fromJson(item)).toList());
        return responsables;
      } else {
        throw Exception('Failed to load responsables');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch responsables: $e');
      rethrow;
    }
  }

  // Get all employees (reactive)
  Future<List<Employe>> getEmployees() async {
    try {
      final response = await http.get(Uri.parse(baseUrlEmployes));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        employees.assignAll(data.map((item) => Employe.fromJson(item)).toList());
        return employees;
      } else {
        throw Exception('Failed to load employees');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch employees: $e');
      rethrow;
    }
  }

  // Update employee
  Future<void> updateEmployee(String id, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrlEmployes/$id'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(updateData),
      );
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Employee updated successfully');
        await getEmployees(); // Refresh list
      } else {
        throw Exception('Failed to update employee');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update employee: $e');
      rethrow;
    }
  }

  // Delete employee
  Future<void> deleteEmployee(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrlEmployes/$id'));
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Employee deleted successfully');
        await getEmployees(); // Refresh list
      } else {
        throw Exception('Failed to delete employee');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete employee: $e');
      rethrow;
    }
  }

  // Update responsable
  Future<void> updateResponsable(String id, Map<String, dynamic> updateData) async {
    try {
      final dataToSend = {
        "nom": updateData["nom"],
        "prenom": updateData["prenom"],
        "email": updateData["email"],
        "typeResponsable": updateData["typeResponsable"],
        "matricule": updateData["matricule"],
        "datedenaissance": updateData["datedenaissance"],
      };

      final response = await http.put(
        Uri.parse('$baseUrlResponsables/$id'),
        headers: {"Content-Type": "application/json"},
        body: json.encode(dataToSend),
      );

      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Responsable updated successfully');
        await getResponsables(); // Refresh list
      } else {
        throw Exception('Failed to update responsable: ${response.body}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update responsable: $e');
      rethrow;
    }
  }

  // Delete responsable
  Future<void> deleteResponsable(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrlResponsables/$id'));
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Responsable deleted successfully');
        await getResponsables(); // Refresh list
      } else {
        throw Exception('Failed to delete responsable');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete responsable: $e');
      rethrow;
    }
  }
}

// Models (unchanged)
class Responsable {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? matricule;
  final String? datedenaissance;
  final String typeResponsable;

  Responsable({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.matricule,
    this.datedenaissance,
    required this.typeResponsable,
  });

  factory Responsable.fromJson(Map<String, dynamic> json) {
    return Responsable(
      id: json['id'] ?? '',
      nom: json['utilisateur']?['nom'] ?? 'Inconnu',
      prenom: json['utilisateur']?['prenom'] ?? 'Inconnu',
      email: json['utilisateur']?['email'] ?? 'Inconnu',
      matricule: json['utilisateur']?['matricule'],
      datedenaissance: json['utilisateur']?['datedenaissance']?.toString(),
      typeResponsable: json['typeResponsable'] ?? 'CHEF_EQUIPE',
    );
  }
}

class Employe {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final Responsable? responsable;

  Employe({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.responsable,
  });

  factory Employe.fromJson(Map<String, dynamic> json) {
    return Employe(
      id: json['id'] ?? '',
      nom: json['utilisateur']?['nom'] ?? '',
      prenom: json['utilisateur']?['prenom'] ?? '',
      email: json['utilisateur']?['email'] ?? '',
      responsable: json['responsable'] != null
          ? Responsable.fromJson(json['responsable'])
          : null,
    );
  }
}