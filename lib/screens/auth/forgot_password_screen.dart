import 'package:flutter/material.dart';
import 'package:gestion_equipe_flutter/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  if (!RegExp(r'^.+@.+\..+$').hasMatch(value)) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_emailSent)
                const Text(
                  'Un email de réinitialisation a été envoyé',
                  style: TextStyle(color: Colors.green),
                ),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendResetLink,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Envoyer le lien'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendResetLink() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _emailSent = false;
      });

      try {
        await _authService.forgotPassword(_emailController.text);
        setState(() => _emailSent = true);
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