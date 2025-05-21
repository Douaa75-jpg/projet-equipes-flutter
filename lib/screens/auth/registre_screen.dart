import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final dateController = TextEditingController();

  var nom = ''.obs;
  var prenom = ''.obs;
  var email = ''.obs;
  var motDePasse = ''.obs;
  var role = 'EMPLOYE'.obs;
  var matricule = ''.obs;
  var datedenaissance = ''.obs;
  var chefsEquipe = <dynamic>[].obs;
  var isLoading = false.obs;
  var entrepriseCode = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChefsEquipe();
  }

  @override
  void onClose() {
    dateController.dispose();
    super.onClose();
  }

Future<void> fetchChefsEquipe() async {
  isLoading.value = true;
  try {
    final response = await http.get(
      Uri.parse('http://localhost:3000/utilisateurs/chefs-equipe'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> decodedResponse = json.decode(response.body);
      chefsEquipe.value = decodedResponse.map((chef) => {
        'id': chef['id'] ?? '',
        'nom': chef['nom'] ?? '',
        'prenom': chef['prenom'] ?? '',
        'email': chef['email'] ?? '',
        'matricule': chef['matricule'] ?? '',
      }).toList();
    } else {
      Get.snackbar('Erreur', 'Impossible de charger les chefs d\'équipe');
    }
  } catch (e) {
    Get.snackbar('Erreur', 'Problème de connexion: ${e.toString()}');
    print('Erreur détaillée: $e');
  } finally {
    isLoading.value = false;
  }
}

  Future<void> registerUser() async {
    if (!formKey.currentState!.validate()) return;

    formKey.currentState!.save();

    if (datedenaissance.value.isEmpty) {
      Get.snackbar('Erreur', 'La date de naissance est requise');
      return;
    }

    // Vérification du code entreprise
    if (entrepriseCode.value != 'ZETABOX2024') {
      Get.snackbar(
        'Erreur',
        'Code entreprise invalide. Seuls les employés de Zeta Box peuvent s\'inscrire.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      return;
    }

    final Map<String, dynamic> userData = {
      'nom': nom.value,
      'prenom': prenom.value,
      'email': email.value,
      'motDePasse': motDePasse.value,
      'matricule': matricule.value,
      'datedenaissance': datedenaissance.value,
      'entrepriseCode': entrepriseCode.value,
    };

    if (role.value == 'CHEF_EQUIPE' || role.value == 'RH') {
    userData['role'] = 'RESPONSABLE';
    userData['typeResponsable'] = role.value;
  } else {
    userData['role'] = 'EMPLOYE';
  }
print('Données envoyées: $userData'); // Debug

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/utilisateurs'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 201) {
        Get.snackbar(
          'Succès',
          'Utilisateur créé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.offAllNamed('/login'); // Redirection vers la page de connexion
      } else {
        final error =
            json.decode(response.body)['message'] ?? 'Erreur inconnue';
        Get.snackbar('Erreur', error);
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Problème de connexion: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}

class RegisterPage extends StatelessWidget {
  final RegisterController controller = Get.put(RegisterController());
  final primaryColor = Color(0xFF8B0000);
  final backgroundColor = Color(0xFFF5F5F5);

  RegisterPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Créer un compte',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: controller.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Color(0xFF8B0000),
                        child: Icon(
                          Icons.person_add,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'Informations personnelles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B0000),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField('Nom', Icons.person,
                        (val) => controller.nom.value = val!),
                    _buildTextField('Prénom', Icons.person_outline,
                        (val) => controller.prenom.value = val!),
                    _buildTextField('Email', Icons.email,
                        (val) => controller.email.value = val!,
                        isEmail: true),
                    _buildTextField('Mot de passe', Icons.lock,
                        (val) => controller.motDePasse.value = val!,
                        isPassword: true),
                    _buildTextField('Matricule', Icons.badge,
                        (val) => controller.matricule.value = val ?? ''),
                    _buildTextField(
                      'Code Entreprise',
                      Icons.business,
                      (val) => controller.entrepriseCode.value = val!,
                      isCodeEntreprise: true,
                    ),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildRoleDropdown(),
                    const SizedBox(height: 24),
                    Obx(() => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.registerUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Créer le compte',
                                  style: TextStyle(fontSize: 16),
                                ),
                        )),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Retour',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    Function(String?) onSaved, {
    bool isEmail = false,
    bool isPassword = false,
    bool isCodeEntreprise = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        obscureText: isPassword,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if ((value == null || value.isEmpty) && label != 'Matricule') {
            return 'Veuillez entrer $label';
          }
          if (label == 'Email' &&
              !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value!)) {
            return 'Veuillez entrer un email valide';
          }
          if (label == 'Mot de passe' && value!.length < 6) {
            return 'Le mot de passe doit contenir au moins 6 caractères';
          }
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller.dateController,
        readOnly: true,
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: Get.context!,
            initialDate: DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: primaryColor,
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (pickedDate != null) {
            controller.datedenaissance.value =
                pickedDate.toIso8601String().split('T')[0];
            controller.dateController.text = controller.datedenaissance.value;
          }
        },
        decoration: InputDecoration(
          labelText: 'Date de naissance',
          hintText: 'AAAA-MM-JJ',
          prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez sélectionner une date';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Obx(() => DropdownButtonFormField<String>(
          value: controller.role.value,
          items: const [
            DropdownMenuItem(
              value: 'EMPLOYE',
              child: Text('Employé', style: TextStyle(color: Colors.black87)),
            ),
             DropdownMenuItem(
              value: 'CHEF_EQUIPE', 
              child: Text('Chef d\'équipe',
                  style: TextStyle(color: Colors.black87)),
            ),
            DropdownMenuItem(
              value: 'RH',
              child: Text('RH', style: TextStyle(color: Colors.black87)),
            ),
          ],
          onChanged: (value) {
            controller.role.value = value!;
          },
          decoration: InputDecoration(
            labelText: 'Rôle',
            prefixIcon: Icon(Icons.work, color: primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          dropdownColor: Colors.white,
          icon: Icon(Icons.arrow_drop_down, color: primaryColor),
        ));
  }
}
