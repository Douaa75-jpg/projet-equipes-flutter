import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/responsable_service.dart';
import 'package:intl/intl.dart';  // Ajoute cette ligne pour utiliser DateFormat

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();
  final TextEditingController _typeResponsableController =
      TextEditingController();
  final TextEditingController _matriculeController = TextEditingController();
  final TextEditingController _dateDeNaissanceController = TextEditingController();

  String _typeResponsable = 'RH';  // Valeur par défaut
  final ResponsableService responsableService = ResponsableService();
  bool _isLoading = false;

  // Fonction pour ouvrir le sélecteur de date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Date initiale
      firstDate: DateTime(1900), // Date la plus ancienne que l'on peut choisir
      lastDate: DateTime.now(), // Date la plus récente
    );
    if (picked != null && picked != DateTime.now()) {
      // Formatage de la date en format ISO 8601
      setState(() {
        _dateDeNaissanceController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                widget.role == 'employe'
                    ? 'Créer un employé'
                    : 'Créer un responsable',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(_nomController, "Nom"),
              const SizedBox(height: 12),
              _buildTextField(_prenomController, "Prénom"),
              const SizedBox(height: 12),
              _buildTextField(_emailController, "Email", isEmail: true),
              const SizedBox(height: 12),
              _buildTextField(_motDePasseController, "Mot de Passe", isPassword: true),
              const SizedBox(height: 12),
              if (widget.role == 'responsable')
                _buildDropdownField(), // Ajout de la sélection pour le type de responsable
              const SizedBox(height: 12),
              _buildTextField(_matriculeController, "Matricule"),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: _buildTextField(
                    _dateDeNaissanceController,
                    "Date de Naissance",
                    isEmail: false,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14.0, horizontal: 20.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: const Text(
                        'Créer',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isPassword = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label, // Affiche le label au-dessus du champ
        hintText: "Entrer votre $label", // Affiche un texte dans le champ comme exemple
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      ),
      obscureText: isPassword,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label est obligatoire';
        }
        if (isEmail && !value.contains('@')) {
          return 'Email invalide';
        }
        return null;
      },
    );
  }

  // Méthode pour construire le champ de sélection du type de responsable
  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _typeResponsable,
      decoration: InputDecoration(
        labelText: "Type de Responsable",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      items: [
        DropdownMenuItem(
          value: 'RH',
          child: Text('RH'),
        ),
        DropdownMenuItem(
          value: 'CHEF_EQUIPE',
          child: Text('Chef d\'équipe'),
        ),
      ],
      onChanged: (value) {
        setState(() {
          _typeResponsable = value!;
        });
      },
      validator: (value) {
        if (value == null) {
          return "Veuillez sélectionner un type de responsable";
        }
        return null;
      },
    );
  }

 void _submitForm() async {
  if (_formKey.currentState?.validate() ?? false) {
    setState(() {
      _isLoading = true;
    });

    // Validation de la date de naissance (ISO 8601 complet)
    String dateDeNaissance = _dateDeNaissanceController.text;
    final parsedDate = DateFormat('yyyy-MM-dd').parseLoose(dateDeNaissance, true);

    if (parsedDate == null) {
      _showSnackBar("La date de naissance doit être au format ISO 8601 (yyyy-MM-dd).", isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    }
    // Formatage de la date au format ISO 8601 complet
    final formattedDate = DateFormat("yyyy-MM-dd").format(parsedDate);

       print("Formatted Date: $formattedDate");

    
    // Validation du type de responsable
    if (_typeResponsable != 'RH' && _typeResponsable != 'CHEF_EQUIPE') {
      _showSnackBar("Le type de responsable doit être 'RH' ou 'CHEF_EQUIPE'.", isError: true);
      setState(() {
        _isLoading = false;
      });
      return;
    }

     // Si l'utilisateur est un responsable, envoie la valeur de _typeResponsable
    String typeResponsable = widget.role == 'responsable'
        ? _typeResponsable
        : ''; // Si c'est un employé, pas de type à envoyer

    final response = widget.role == 'employe'
        ? await responsableService.createEmploye(
            _nomController.text,
            _prenomController.text,
            _emailController.text,
            _motDePasseController.text,
            _matriculeController.text,
            dateDeNaissance,  // Utilisation de la date validée
          )
         : await responsableService.createResponsable(
            _nomController.text,
            _prenomController.text,
            _emailController.text,
            _motDePasseController.text,
            _matriculeController.text,
            formattedDate,  // Envoie la date formatée ISO 8601
            typeResponsable,
          );

    if (mounted) {
      _handleResponse(response);
    }

    setState(() {
      _isLoading = false;
    });
  }
}
  void _handleResponse(http.Response response) {
    if (response.statusCode == 201) {
      _showSnackBar("Création réussie !");
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pop(context);
      });
    } else {
      _showSnackBar("Erreur: ${response.body}", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }
}
