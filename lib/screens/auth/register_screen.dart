import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/responsable_service.dart';

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

  final ResponsableService responsableService = ResponsableService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTextField(_nomController, "Nom"),
              _buildTextField(_prenomController, "Prénom"),
              _buildTextField(_emailController, "Email", isEmail: true),
              _buildTextField(_motDePasseController, "Mot de Passe",
                  isPassword: true),
              if (widget.role == 'responsable')
                _buildTextField(
                    _typeResponsableController, "Type de Responsable"),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Créer'),
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
      decoration: InputDecoration(labelText: label),
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

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // Déclaration correcte avec String? pour accepter null
      String typeResponsable = widget.role == 'responsable'
          ? _typeResponsableController.text
          : ''; // Si c'est un employé, on envoie une chaîne vide, sinon le type de responsable

      // Vérification que le typeResponsable est correct si le rôle est 'responsable'
      if (widget.role == 'responsable' && !['RH', 'CHEF_EQUIPE'].contains(typeResponsable)) {
        _showSnackBar("Type de responsable doit être RH ou CHEF_EQUIPE.", isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Envoi de la requête en fonction du rôle
      final response = widget.role == 'employe'  // Corriger 'EMPLOYE' en 'employe'
          ? await responsableService.createEmploye(
              _nomController.text,
              _prenomController.text,
              _emailController.text,
              _motDePasseController.text,
            )
          : await responsableService.createResponsable(
              _nomController.text,
              _prenomController.text,
              _emailController.text,
              _motDePasseController.text,
              typeResponsable,  // Passer la chaîne de caractères uniquement pour les responsables
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
        Navigator.pop(context); // Retourner à l'écran précédent
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
