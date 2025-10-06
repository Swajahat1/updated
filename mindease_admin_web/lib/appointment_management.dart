import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppointmentManagementScreen extends StatefulWidget {
  const AppointmentManagementScreen({super.key});

  @override
  _AppointmentManagementScreenState createState() =>
      _AppointmentManagementScreenState();
}

class _AppointmentManagementScreenState
    extends State<AppointmentManagementScreen> {
  List<Map<String, dynamic>> _appointments = [];
  List<Map<String, dynamic>> _filteredAppointments = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
    _searchController.addListener(_filterAppointments);
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Fetching appointments from API...');
      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/appointments'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Appointments API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(
            '✅ Appointments fetched successfully: ${data.length} appointments');
        setState(() {
          _appointments = data.cast<Map<String, dynamic>>();
          _filteredAppointments = _appointments;
          _isLoading = false;
        });
      } else {
        print(
            '❌ Appointments API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
      print('❌ Exception in _fetchAppointments: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to fetch appointments: $e');
    }
  }

  void _filterAppointments() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAppointments = _appointments.where((appointment) {
        final userEmail =
            appointment['userEmail']?.toString().toLowerCase() ?? '';
        final therapistEmail =
            appointment['therapistEmail']?.toString().toLowerCase() ?? '';
        final type = appointment['type']?.toString().toLowerCase() ?? '';
        final status = appointment['status']?.toString().toLowerCase() ?? '';
        return userEmail.contains(query) ||
            therapistEmail.contains(query) ||
            type.contains(query) ||
            status.contains(query);
      }).toList();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText:
                    'Search appointments by user, therapist, type, or status...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Appointments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAppointments.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No appointments found',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFF8C42),
                                    Color(0xFFFF6B35)
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Appointments (${_filteredAppointments.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.refresh,
                                        color: Colors.white),
                                    onPressed: _fetchAppointments,
                                  ),
                                ],
                              ),
                            ),
                            // Appointments List
                            Expanded(
                              child: ListView.builder(
                                itemCount: _filteredAppointments.length,
                                itemBuilder: (context, index) {
                                  final appointment =
                                      _filteredAppointments[index];
                                  return _buildAppointmentTile(appointment);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentTile(Map<String, dynamic> appointment) {
    final userEmail = appointment['userEmail'] ?? 'N/A';
    final therapistEmail = appointment['therapistEmail'] ?? 'N/A';
    final type = appointment['type'] ?? 'N/A';
    final status = appointment['status'] ?? 'Pending';
    final fee = appointment['fee']?.toString() ?? '0.00';
    final appointmentDate = appointment['appointmentDate'] != null
        ? DateTime.parse(appointment['appointmentDate']).toLocal()
        : null;
    final appointmentTime = appointment['appointmentTime'] ?? 'N/A';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            Icons.calendar_today,
            color: statusColor,
          ),
        ),
        title: Text(
          'User: $userEmail',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Therapist: $therapistEmail'),
            const SizedBox(height: 4),
            if (appointmentDate != null)
              Text(
                  'Date: ${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}'),
            Text('Time: $appointmentTime'),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Fee: \$$fee',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green[600],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _editAppointment(appointment),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Edit'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _cancelAppointment(appointment),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _editAppointment(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Appointment'),
        content: Text(
            'Edit functionality for appointment ${appointment['_id']} would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _cancelAppointment(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content:
            const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cancel functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Cancel functionality would be implemented here'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
