import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Pour formater les dates
import 'package:gestion_equipe_flutter/services/demande_service.dart';
import 'package:gestion_equipe_flutter/services/notification_service.dart'; // Import pour NotificationService

class DemandeScreen extends StatefulWidget {
  final String employeId;

  DemandeScreen({required this.employeId});

  @override
  _DemandeScreenState createState() => _DemandeScreenState();
}

class _DemandeScreenState extends State<DemandeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _typeDemande;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String? _raison;

  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();

  bool _isSubmitting = false;

  final demandeService = DemandeService();
  final NotificationService _notificationService = NotificationService();
  String? _lastNotification;

  @override
  void initState() {
    super.initState();

    // Connexion à WebSocket avec l'ID de l'employé
    _notificationService.connect(widget.employeId, (message) {
      // Lorsque nous recevons une notification, nous l'affichons à l'utilisateur
      setState(() {
        _lastNotification = message;
      });

      // Affichage d'un SnackBar avec la notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    // Déconnexion de WebSocket lorsque l'écran est supprimé
    _notificationService.disconnect();
    super.dispose();
  }

  Future<void> _selectDateTime(TextEditingController controller, bool isStartDate) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        setState(() {
          if (isStartDate) {
            _dateDebut = selectedDateTime;
          } else {
            _dateFin = selectedDateTime;
          }
          controller.text = DateFormat('yyyy-MM-dd – kk:mm').format(selectedDateTime);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateDebut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez sélectionner une date de début")),
      );
      return;
    }

    if (_dateDebut!.isBefore(DateTime.now())) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("⏰ La date de début doit être dans le futur")),
    );
    return;
  }

    if (_dateFin != null && _dateFin!.isBefore(_dateDebut!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("La date de fin doit être après la date de début")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final demande = {
      'employeId': widget.employeId,
      'type': _typeDemande?.toLowerCase(),
      'dateDebut': _dateDebut?.toIso8601String(),
      'dateFin': _dateFin?.toIso8601String(),
      'raison': _raison,
    };

    final success = await demandeService.createDemande(demande);

    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Demande soumise avec succès')),
      );
      Navigator.pop(context); // Retour à l'écran précédent après succès
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur lors de l\'envoi de la demande')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Faire une Demande")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _typeDemande,
                onChanged: (newValue) => setState(() => _typeDemande = newValue),
                items: [
                  DropdownMenuItem(value: 'congé', child: Text('Congé')),
                  DropdownMenuItem(value: 'absence', child: Text('Absence')),
                  DropdownMenuItem(value: 'autorisation_sortie', child: Text('Autorisation de sortie')),
                ],
                decoration: InputDecoration(labelText: "Type de Demande"),
                validator: (value) =>
                    value == null ? 'Veuillez sélectionner un type de demande' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: "Raison"),
                onChanged: (value) => _raison = value,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Veuillez fournir une raison' : null,
              ),
              TextFormField(
                controller: _dateDebutController,
                decoration: InputDecoration(labelText: "Date de début"),
                readOnly: true,
                onTap: () => _selectDateTime(_dateDebutController, true),
              ),
              TextFormField(
                controller: _dateFinController,
                decoration: InputDecoration(labelText: "Date de fin (facultative)"),
                readOnly: true,
                onTap: () => _selectDateTime(_dateFinController, false),
              ),
              SizedBox(height: 20),
              _isSubmitting
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Soumettre'),
                    ),
              if (_lastNotification != null) // Affichage de la dernière notification
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Dernière notification: $_lastNotification"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Fonction simulée pour envoyer une demande
  void _sendRequest() {
    // Exemple: Vous pouvez remplacer cette logique par un appel API pour envoyer une demande.
    _notificationService.sendNotification(widget.employeId, "Votre demande a été acceptée.");
  }
}
