import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gestion_equipe_flutter/services/demande_service.dart';
import 'package:gestion_equipe_flutter/services/notification_service.dart';

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

  final _dateDebutController = TextEditingController();
  final _dateFinController = TextEditingController();

  bool _isSubmitting = false;
  bool _showSuccessAnimation = false;

  final demandeService = DemandeService();
  final NotificationService _notificationService = NotificationService();
  String? _lastNotification;

  // Couleurs adaptées à ZETABOX
  final Color _primaryColor = const Color(0xFF2C3E50); // لون الشريط
  final Color _buttonColor = const Color(0xFFD32F2F); // لون الزر
  final Color _backgroundColor = const Color(0xFFF8F9FA); // لون الخلفية
  final Color _textColor = const Color(0xFF333333); // لون النصوص الرئيسية
  final Color _borderColor = const Color(0xFFDDDDDD); // لون الحدود

  @override
  void initState() {
    super.initState();
    _notificationService.connect(widget.employeId, (message) {
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
            dialogTheme: DialogTheme(
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

    if (_dateDebut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Veuillez sélectionner une date de début")),
      );
      return;
    }

    if (_dateDebut!.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⏰ La date de début doit être dans le futur")),
      );
      return;
    }

    if (_dateFin != null && _dateFin!.isBefore(_dateDebut!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("La date de fin doit être après la date de début")),
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
      setState(() => _showSuccessAnimation = true);
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _showSuccessAnimation = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Demande soumise avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❌ Erreur lors de l\'envoi de la demande'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _borderColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: Center(
          child: Image.asset(
            'assets/logo.png',
            height: 55,
            fit: BoxFit.contain,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            children: [
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Nouvelle ',
                      style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.width > 600 ? 36 : 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2F3A4C),
                        shadows: const [
                          Shadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    TextSpan(
                      text: 'Demande',
                      style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.width > 600 ? 36 : 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: _backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withAlpha((0.5 * 255).toInt()),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(3, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Formulaire de Demande",
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                              textAlign: TextAlign.left,
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCaptchaRow(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                    if (_lastNotification != null) _buildNotificationBadge(),
                  ],
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
      items: [
        DropdownMenuItem(
          value: 'congé',
          child: Text('Congé', style: TextStyle(color: _textColor)),
        ),
        DropdownMenuItem(
          value: 'absence',
          child: Text('Absence', style: TextStyle(color: _textColor)),
        ),
        DropdownMenuItem(
          value: 'autorization_sortie',
          child: Text('Autorisation de sortie',
              style: TextStyle(color: _textColor)),
        ),
      ],
      decoration: InputDecoration(
        labelText: "Type de Demande *",
        labelStyle: TextStyle(color: _textColor.withAlpha((0.7 * 255).toInt())),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _buttonColor),
        ),
        filled: true,
        fillColor: _backgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: TextStyle(color: _textColor),
      icon: Icon(Icons.arrow_drop_down,
          color: _textColor.withAlpha(179)), // 0.7 * 255 ≈ 179
      validator: (value) =>
          value == null ? 'Veuillez sélectionner un type de demande' : null,
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      decoration: InputDecoration(
        labelText: "Raison *",
        labelStyle: TextStyle(color: _textColor.withAlpha((0.7 * 255).toInt())),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _buttonColor),
        ),
        filled: true,
        fillColor: _backgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: TextStyle(color: _textColor),
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
        labelStyle: TextStyle(color: _textColor.withAlpha((0.7 * 255).toInt())),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _buttonColor),
        ),
        filled: true,
        fillColor: _backgroundColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon:
            Icon(Icons.calendar_today, color: _textColor.withAlpha(179)),
      ),
      style: TextStyle(color: _textColor),
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
          const Text(
            "Je ne suis pas un robot",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Icon(Icons.verified_user, color: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isWeb = Theme.of(context).platform == TargetPlatform.fuchsia ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: ElevatedButton(
          onHover: isWeb
              ? (hovering) {
                  setState(() {});
                }
              : null,
          onPressed: _isSubmitting ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: isWeb ? 5 : 2,
          ),
          child: _isSubmitting
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : _showSuccessAnimation
                  ? const Icon(Icons.check_circle,
                      color: Colors.white, size: 24)
                  : const Text(
                      'Soumettre La Demande',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
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
          color: _primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _primaryColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.notifications, color: _buttonColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _lastNotification ?? '',
                style: TextStyle(color: _textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
