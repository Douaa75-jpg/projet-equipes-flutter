import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_equipe_flutter/services/demande_service.dart';
import 'package:gestion_equipe_flutter/services/notification_service.dart';
import 'package:gestion_equipe_flutter/screens/layoutt/employee_layout.dart';
import 'package:flutter/services.dart'; // Pour rootBundle

class DemandeScreen extends StatefulWidget {
  final String employeId;

  const DemandeScreen({Key? key, required this.employeId}) : super(key: key);

  @override
  _DemandeScreenState createState() => _DemandeScreenState();
}

class _DemandeScreenState extends State<DemandeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _typeDemande;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String? _raison;
  int _soldeConges = 30;

  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();

  bool _isSubmitting = false;
  bool _showSuccessAnimation = false;

  final demandeService = DemandeService();
  final NotificationService _notificationService = NotificationService();
  String? _lastNotification;

  // Mapping des types de demande
  final Map<String, String> _typeMapping = {
    'congé': 'CONGE',
    'absence': 'ABSENCE',
    'autorization_sortie': 'AUTORISATION_SORTIE'
  };

  // Couleurs harmonisées avec EmployeeLayout
  final Color _primaryColor = const Color(0xFF8B0000);
  final Color _buttonColor = const Color(0xFF8B0000);
  final Color _backgroundColor = Colors.white;
  final Color _textColor = Colors.black87;
  final Color _borderColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _initializeNotificationService();
     _loadSoldeConges();
    _loadAsset();
  }

  Future<void> _loadAsset() async {
    try {
      await rootBundle.load('assets/equipe.png');
    } catch (e) {
      print('Error loading asset: $e');
    }
  }

   Future<void> _loadSoldeConges() async {
    try {
      final solde = await demandeService.getSoldeConges(widget.employeId);
      if (mounted) {
        setState(() => _soldeConges = solde);
      }
    } catch (e) {
      print('Erreur chargement solde: $e');
      if (mounted) {
        setState(() => _soldeConges = 30); // Valeur par défaut en cas d'erreur
      }
    }
  }

  void _initializeNotificationService() {
    _notificationService.connect(widget.employeId, (message) {
      if (!mounted) return;
      setState(() {
        _lastNotification = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  @override
  void dispose() {
    _notificationService.disconnect();
    _dateDebutController.dispose();
    _dateFinController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(
      TextEditingController controller, bool isStartDate) async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _primaryColor,
            ),
            dialogTheme: const DialogTheme(
              backgroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: _primaryColor,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: _primaryColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        final selectedDateTime =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
        if (!mounted) return;
        setState(() {
          if (isStartDate) {
            _dateDebut = selectedDateTime;
          } else {
            _dateFin = selectedDateTime;
          }
          controller.text =
              DateFormat('yyyy-MM-dd – kk:mm').format(selectedDateTime);
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_typeDemande == 'congé') {
      final days =
          _dateFin != null ? _dateFin!.difference(_dateDebut!).inDays + 1 : 1;

      if (_soldeConges < days) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('❌ Solde insuffisant. Il vous reste $_soldeConges jours'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }
    if (_dateDebut == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Veuillez sélectionner une date de début")),
      );
      return;
    }

    if (_dateDebut!.isBefore(DateTime.now())) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⏰ La date de début doit être dans le futur")),
      );
      return;
    }

    if (_dateFin != null && _dateFin!.isBefore(_dateDebut!)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("La date de fin doit être après la date de début")),
      );
      return;
    }

    if (_typeDemande == null || _typeMapping[_typeDemande!] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner un type valide")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final demande = {
        'employeId': widget.employeId,
        'type': _typeMapping[_typeDemande!], // Utilisation du mapping
        'dateDebut': _dateDebut!.toIso8601String(),
        'dateFin': _dateFin?.toIso8601String(),
        'raison': _raison,
      };

      final success = await demandeService.createDemande(demande);

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (success) {
        setState(() => _showSuccessAnimation = true);
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        setState(() => _showSuccessAnimation = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demande soumise avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Erreur lors de l\'envoi de la demande'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmployeeLayout(
      title: 'Nouvelle Demande',
      notificationService: _notificationService,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Nouvelle Demande',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B0000),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _buildDropdownField(),
                        const SizedBox(height: 16),
                        _buildReasonField(),
                        const SizedBox(height: 16),
                        _buildDateField(
                            _dateDebutController, "Date de début *", true),
                        const SizedBox(height: 16),
                        _buildDateField(_dateFinController,
                            "Date de fin (optionnelle)", false),
                        if (_typeDemande == 'congé')
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Solde disponible: $_soldeConges jours',
                                  style: TextStyle(
                                    color: _soldeConges > 0
                                        ? _primaryColor
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_soldeConges <= 0)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Vous n\'avez plus de jours de congé disponibles',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        _buildCaptchaRow(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                        if (_lastNotification != null)
                          _buildNotificationBadge(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _typeDemande,
      onChanged: (newValue) => setState(() => _typeDemande = newValue),
      items: const [
        DropdownMenuItem(
          value: 'congé',
          child: Text('Congé'),
        ),
        DropdownMenuItem(
          value: 'absence',
          child: Text('Absence'),
        ),
        DropdownMenuItem(
          value: 'autorization_sortie',
          child: Text('Autorisation de sortie'),
        ),
      ],
      decoration: InputDecoration(
        labelText: "Type de Demande *",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) =>
          value == null ? 'Veuillez sélectionner un type de demande' : null,
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Raison *",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      maxLines: 3,
      onChanged: (value) => _raison = value,
      validator: (value) =>
          value == null || value.isEmpty ? 'Veuillez fournir une raison' : null,
    );
  }

  Widget _buildDateField(
      TextEditingController controller, String label, bool isRequired) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: () => _selectDateTime(controller, isRequired),
      validator: isRequired
          ? (value) =>
              value == null || value.isEmpty ? 'Ce champ est obligatoire' : null
          : null,
    );
  }

  Widget _buildCaptchaRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: _borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Checkbox(
            value: false,
            onChanged: (val) {},
            activeColor: _buttonColor,
          ),
          const SizedBox(width: 8),
          const Text("Je ne suis pas un robot"),
          const Spacer(),
          const Icon(Icons.verified_user, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: _buttonColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : _showSuccessAnimation
              ? const Icon(Icons.check_circle, color: Colors.white, size: 24)
              : const Text(
                  'Soumettre La Demande',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
    );
  }

  Widget _buildNotificationBadge() {
    return AnimatedOpacity(
      opacity: _lastNotification != null ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications, color: _buttonColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_lastNotification ?? ''),
            ),
          ],
        ),
      ),
    );
  }
}
