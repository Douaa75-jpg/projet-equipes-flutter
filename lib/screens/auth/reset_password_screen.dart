import 'package:flutter/material.dart';
import 'package:gestion_equipe_flutter/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  
  const ResetPasswordScreen({Key? key, required this.token}) : super(key: key);

  @override
  _ResetPasswordScreenState createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _success = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réinitialisation')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un mot de passe';
                  }
                  if (value.length < 8) {
                    return '8 caractères minimum';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_success)
                const Text(
                  'Mot de passe réinitialisé avec succès',
                  style: TextStyle(color: Colors.green),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Réinitialiser'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _success = false;
      });

      try {
        await _authService.resetPassword(
          widget.token,
          _passwordController.text,
        );
        setState(() => _success = true);
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}