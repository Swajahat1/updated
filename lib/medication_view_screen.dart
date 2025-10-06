import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:myapp/theme/app_theme.dart';

class MedicationViewScreen extends StatefulWidget {
  final String userId;

  const MedicationViewScreen({super.key, required this.userId});

  @override
  State<MedicationViewScreen> createState() => _MedicationViewScreenState();
}

class _MedicationViewScreenState extends State<MedicationViewScreen> {
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _todaySchedule = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedications();
    _fetchTodaySchedule();
  }

  Future<void> _fetchMedications() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/medications/user/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _medications = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load medications');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load medications: $e');
    }
  }

  Future<void> _fetchTodaySchedule() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/medications/user/${widget.userId}/today'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _todaySchedule = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print('Error fetching today schedule: $e');
    }
  }

  Future<void> _logMedicationIntake(String medicationId, bool taken) async {
    try {
      final response = await http.post(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/medications/$medicationId/log'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'taken': taken,
          'date': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        _fetchTodaySchedule(); // Refresh schedule
        _showSuccessSnackBar(taken
            ? 'Medication logged as taken'
            : 'Medication logged as missed');
      } else {
        throw Exception('Failed to log medication');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to log medication: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Medications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medications.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_todaySchedule.isNotEmpty) ...[
                        const Text(
                          'Today\'s Schedule',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._todaySchedule
                            .map((schedule) => _buildScheduleCard(schedule)),
                        const SizedBox(height: 24),
                      ],
                      const Text(
                        'All Medications',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._medications.map(
                          (medication) => _buildMedicationCard(medication)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.medication_outlined,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Medications Prescribed',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your therapist will prescribe medications here after your appointments.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final taken = schedule['taken'] ?? false;
    final time = schedule['time'] ?? '';
    final medicationName = schedule['medicationName'] ?? '';
    final dosage = schedule['dosage'] ?? '';
    final instructions = schedule['instructions'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: taken ? Colors.green[100] : Colors.orange[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                taken ? Icons.check_circle : Icons.schedule,
                color: taken ? Colors.green : Colors.orange,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicationName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text('$dosage at $time'),
                  if (instructions.isNotEmpty)
                    Text(
                      instructions,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            if (!taken)
              ElevatedButton(
                onPressed: () =>
                    _logMedicationIntake(schedule['medicationId'], true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Take'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    final name = medication['name'] ?? '';
    final dosage = medication['dosage'] ?? '';
    final frequency = medication['frequency'] ?? '';
    final isActive = medication['isActive'] ?? true;
    final prescribedBy = medication['prescribedBy'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? Colors.green[700] : Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Dosage: $dosage'),
            Text('Frequency: $frequency'),
            if (prescribedBy.isNotEmpty) Text('Prescribed by: $prescribedBy'),
          ],
        ),
      ),
    );
  }
}
