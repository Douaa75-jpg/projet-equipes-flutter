import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../services/pointage_service.dart';

class HeuresTravailScreen extends StatefulWidget {
  final String employeId;
  final String employeNom;
  final String employePrenom;

  const HeuresTravailScreen({
    Key? key,
    required this.employeId,
    required this.employeNom,
    required this.employePrenom,
  }) : super(key: key);

  @override
  _HeuresTravailScreenState createState() => _HeuresTravailScreenState();
}

class _HeuresTravailScreenState extends State<HeuresTravailScreen> {
  final PointageService _pointageService = PointageService();
  final DateRangePickerController _dateController = DateRangePickerController();
  
  DateTime? _selectedDate;
  bool _isLoading = false;
  List<dynamic> _historique = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadHistorique();
  }

  Future<void> _loadHistorique() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      String? dateStr;
      if (_selectedDate != null) {
        dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      }

      final result = await _pointageService.getHistorique(
        widget.employeId, 
        dateStr ?? DateFormat('yyyy-MM-dd').format(DateTime.now())
      );

      setState(() {
        _historique = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onDateChanged(DateRangePickerSelectionChangedArgs args) {
    if (args.value is DateTime) {
      setState(() {
        _selectedDate = args.value as DateTime;
      });
    }
  }

  void _applyDateFilter() {
    _loadHistorique();
  }

  void _resetDateFilter() {
    _dateController.selectedDate = null;
    setState(() {
      _selectedDate = null;
    });
    _loadHistorique();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique de pointage - ${widget.employePrenom} ${widget.employeNom}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _showDatePickerDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _historique.isEmpty
                  ? const Center(child: Text('Aucun pointage trouvé'))
                  : _buildHistoriqueList(),
    );
  }

 Widget _buildHistoriqueList() {
  return ListView.builder(
    itemCount: _historique.length,
    itemBuilder: (context, index) {
      final pointage = _historique[index];
      final heure = pointage['heure'] is String 
          ? DateFormat('HH:mm:ss').parse(pointage['heure'])
          : DateTime.now();
      final date = pointage['date'] is String 
          ? DateFormat('yyyy-MM-dd').parse(pointage['date'])
          : DateTime.now();

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: Icon(
            pointage['type'] == 'ENTREE' ? Icons.login : Icons.logout,
            color: pointage['type'] == 'ENTREE' ? Colors.green : Colors.red,
          ),
          title: Text(
            '${pointage['typeLibelle'] ?? (pointage['type'] == 'ENTREE' ? 'Entrée' : 'Sortie')} - ${DateFormat('HH:mm').format(heure)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${DateFormat('dd/MM/yyyy').format(date)}'),
              if (pointage['employe'] != null)
                Text('Matricule: ${pointage['employe']['matricule']}'),
            ],
          ),
          trailing: Text(
            pointage['type'] == 'ENTREE' ? 'Entrée' : 'Sortie',
            style: TextStyle(
              color: pointage['type'] == 'ENTREE' ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    },
  );
}

  void _showDatePickerDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Choisir une date'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SfDateRangePicker(
                controller: _dateController,
                selectionMode: DateRangePickerSelectionMode.single,
                onSelectionChanged: _onDateChanged,
                initialSelectedDate: _selectedDate,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _resetDateFilter,
                    child: const Text('Réinitialiser'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _applyDateFilter();
                      Get.back();
                    },
                    child: const Text('Valider'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}