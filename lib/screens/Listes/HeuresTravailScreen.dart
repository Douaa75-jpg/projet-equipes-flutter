import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../services/pointage_service.dart';

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
  State<HeuresTravailScreen> createState() => _HeuresTravailScreenState();
}

class _HeuresTravailScreenState extends State<HeuresTravailScreen> {
  final PointageService _pointageService = Get.find();
  final RxString selectedDate = ''.obs; // Vide par défaut pour afficher tous les pointages
  final RxList<dynamic> allPointages = <dynamic>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    debugPrint('Chargement des pointages pour employé: ${widget.employeId}');
    _loadAllPointages();
  }

void _loadAllPointages() async {
  try {
    isLoading.value = true;
    final pointages = await _pointageService.getHistorique(widget.employeId, '');
    
    debugPrint('Pointages reçus: ${pointages.toString()}'); // Ajoutez ce log
    
    allPointages.assignAll(pointages);
  } catch (e) {
    debugPrint('Erreur détaillée: ${e.toString()}'); // Log plus détaillé
    Get.snackbar('Erreur', 'Impossible de charger les pointages: ${e.toString()}');
  } finally {
    isLoading.value = false;
  }
}

  List<dynamic> get filteredPointages {
    if (selectedDate.value.isEmpty) return allPointages;
    return allPointages.where((pointage) {
      return pointage['date'] == selectedDate.value;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historique pointage - ${widget.employePrenom} ${widget.employeNom}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt_off),
            onPressed: () {
              selectedDate.value = '';
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDateSelector(),
            const SizedBox(height: 20),
            Expanded(
              child: _buildHistoriqueTable(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAllPointages,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Obx(() => Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedDate.value.isEmpty 
                ? 'Tous les pointages' 
                : 'Pointages du: ${selectedDate.value}',
              style: const TextStyle(fontSize: 16),
            ),
            if (selectedDate.value.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => selectedDate.value = DateFormat('yyyy-MM-dd').format(DateTime.now()),
              ),
          ],
        ),
      ),
    ));
  }

  Widget _buildHistoriqueTable() {
    return Obx(() {
      if (isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (allPointages.isEmpty) {
        return const Center(child: Text('Aucun pointage trouvé pour cet employé'));
      }

      final pointages = filteredPointages;

      if (pointages.isEmpty) {
        return Center(child: Text(
          selectedDate.value.isEmpty
            ? 'Aucun pointage trouvé'
            : 'Aucun pointage trouvé pour cette date',
        ));
      }

      return Card(
        elevation: 4,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            columnSpacing: 20,
            dataRowHeight: 50,
            columns: const [
              DataColumn(label: Text('Heure', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: pointages.map((pointage) {
              return DataRow(
                cells: [
                  DataCell(Text(pointage['heure'] ?? '--')),
                  DataCell(
                    Chip(
                      label: Text(
                        pointage['typeLibelle'] ?? '--',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: pointage['type'] == 'ENTREE' 
                        ? Colors.green 
                        : Colors.red,
                    ),
                  ),
                  DataCell(Text(pointage['date'] ?? '--')),
                ],
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value.isEmpty 
        ? DateTime.now() 
        : DateFormat('yyyy-MM-dd').parse(selectedDate.value),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      selectedDate.value = DateFormat('yyyy-MM-dd').format(picked);
    }
  }
}