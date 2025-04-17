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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textStyle = const TextStyle(fontSize: 16, color: Colors.black);

    return Scaffold(
       backgroundColor: Color.fromARGB(255, 249, 233, 236), 
      appBar: AppBar(
        title: const Text('Créer un compte '),
        backgroundColor: primaryColor,
        foregroundColor: Color(0xFFFFEBEE),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    buildTextField('Nom', (val) => nom = val!, textStyle),
                    buildTextField('Prénom', (val) => prenom = val!, textStyle),
                    buildTextField('Email', (val) => email = val!, textStyle, isEmail: true),
                    buildTextField('Mot de passe', (val) => motDePasse = val!, textStyle, isPassword: true),
                    buildTextField('Matricule', (val) => matricule = val, textStyle),
                    buildDateField(textStyle),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: role,
                      items: const [
                        DropdownMenuItem(value: 'EMPLOYE', child: Text('Employé')),
                        DropdownMenuItem(value: 'RESPONSABLE', child: Text('Responsable (Chef d\'équipe)')),
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
                        labelStyle: textStyle,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    if (role == 'EMPLOYE') ...[
                      const SizedBox(height: 16),
                      isLoading
                          ? const CircularProgressIndicator()
                          : DropdownButtonFormField<String>(
                              value: selectedResponsableId,
                              items: chefsEquipe.map<DropdownMenuItem<String>>((chef) {
                                return DropdownMenuItem(
                                  value: chef['id'],
                                  child: Text('${chef['nom']} ${chef['prenom']}'),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => selectedResponsableId = value),
                              decoration: InputDecoration(
                                labelText: 'Responsable',
                                labelStyle: textStyle,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Créer'),
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

  Widget buildTextField(String label, Function(String?) onSaved, TextStyle style,
      {bool isEmail = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: style,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget buildDateField(TextStyle style) {
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
          labelStyle: style,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
