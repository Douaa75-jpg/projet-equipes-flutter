import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController dateController = TextEditingController();

  String nom = '';
  String prenom = '';
  String email = '';
  String motDePasse = '';
  String role = 'EMPLOYE';
  String? matricule;
  String? datedenaissance;
  String? selectedResponsableId;
  List<dynamic> chefsEquipe = [];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchChefsEquipe();
  }

  Future<void> fetchChefsEquipe() async {
    setState(() => isLoading = true);
    final response = await http.get(Uri.parse('http://localhost:3000/utilisateurs/chefs-equipe'));
    if (response.statusCode == 200) {
      setState(() {
        chefsEquipe = json.decode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print('Erreur lors du chargement des chefs d\'équipe');
    }
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    if (role == 'EMPLOYE' && selectedResponsableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un responsable.')),
      );
      return;
    }

    if (datedenaissance == null || datedenaissance!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date de naissance est requise.')),
      );
      return;
    }

    final Map<String, dynamic> userData = {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'motDePasse': motDePasse,
      'role': role,
      'matricule': matricule,
      'datedenaissance': datedenaissance,
    };

    if (role == 'EMPLOYE' && selectedResponsableId != null) {
      userData['responsableId'] = selectedResponsableId;
    }

    if (role == 'RESPONSABLE') {
      userData['typeResponsable'] = 'CHEF_EQUIPE';
    }

    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse('http://localhost:3000/utilisateurs'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );

    setState(() => isLoading = false);

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur créé avec succès')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF8B0000); // Rouge bordeaux
    final accentColor = Color(0xFFD32F2F); // Rouge plus clair
    final backgroundColor = Color(0xFFF5F5F5); // Fond gris clair
    final textColor = Color(0xFF333333); // Texte foncé

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
                key: _formKey,
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
                    _buildTextField('Nom', Icons.person, (val) => nom = val!),
                    _buildTextField('Prénom', Icons.person_outline, (val) => prenom = val!),
                    _buildTextField('Email', Icons.email, (val) => email = val!, isEmail: true),
                    _buildTextField('Mot de passe', Icons.lock, (val) => motDePasse = val!,
                        isPassword: true),
                    _buildTextField('Matricule', Icons.badge, (val) => matricule = val),
                    _buildDateField(),
                    const SizedBox(height: 16),
                    _buildRoleDropdown(),
                    if (role == 'EMPLOYE') ...[
                      const SizedBox(height: 16),
                      _buildResponsableDropdown(),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading ? null : registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: isLoading
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
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
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

  Widget _buildTextField(String label, IconData icon, Function(String?) onSaved,
      {bool isEmail = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Color(0xFF8B0000)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF8B0000)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF8B0000), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        obscureText: isPassword,
        validator: (value) {
          if ((value == null || value.isEmpty) && label != 'Matricule') {
            return 'Veuillez entrer $label';
          }
          if (label == 'Email' && !RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(value!)) {
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
        controller: dateController,
        readOnly: true,
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Color(0xFF8B0000),
                    onPrimary: Colors.white,
                    onSurface: Colors.black,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (pickedDate != null) {
            setState(() {
              datedenaissance = pickedDate.toIso8601String().split('T')[0];
              dateController.text = datedenaissance!;
            });
          }
        },
        decoration: InputDecoration(
          labelText: 'Date de naissance',
          hintText: 'AAAA-MM-JJ',
          prefixIcon: Icon(Icons.calendar_today, color: Color(0xFF8B0000)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF8B0000)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF8B0000), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: role,
      items: const [
        DropdownMenuItem(
          value: 'EMPLOYE',
          child: Text('Employé', style: TextStyle(color: Colors.black87)),
        ),
        DropdownMenuItem(
          value: 'RESPONSABLE',
          child: Text('Chef d\'équipe', style: TextStyle(color: Colors.black87)),
        ),
      ],
      onChanged: (value) {
        setState(() {
          role = value!;
          if (role == 'RESPONSABLE') {
            selectedResponsableId = null;
          }
        });
      },
      decoration: InputDecoration(
        labelText: 'Rôle',
        prefixIcon: Icon(Icons.work, color: Color(0xFF8B0000)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF8B0000)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF8B0000), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      dropdownColor: Colors.white,
      icon: Icon(Icons.arrow_drop_down, color: Color(0xFF8B0000)),
    );
  }

  Widget _buildResponsableDropdown() {
    return isLoading
        ? Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)))
        : DropdownButtonFormField<String>(
            value: selectedResponsableId,
            items: chefsEquipe.map<DropdownMenuItem<String>>((chef) {
              return DropdownMenuItem(
                value: chef['id'],
                child: Text(
                  '${chef['nom']} ${chef['prenom']}',
                  style: TextStyle(color: Colors.black87),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => selectedResponsableId = value),
            decoration: InputDecoration(
              labelText: 'Responsable',
              prefixIcon: Icon(Icons.supervisor_account, color: Color(0xFF8B0000)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF8B0000)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF8B0000), width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            dropdownColor: Colors.white,
            icon: Icon(Icons.arrow_drop_down, color: Color(0xFF8B0000)),
          );
  }
}