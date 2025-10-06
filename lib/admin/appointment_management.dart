import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/theme/app_theme.dart';

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
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Scheduled',
    'Completed',
    'Cancelled',
    'Online',
    'Physical'
  ];

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
      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/appointments'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _appointments = data.cast<Map<String, dynamic>>();
          _filteredAppointments = _appointments;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load appointments');
      }
    } catch (e) {
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

        // Text search
        final matchesSearch = userEmail.contains(query) ||
            therapistEmail.contains(query) ||
            type.contains(query) ||
            status.contains(query);

        // Filter by status/type
        final matchesFilter = _selectedFilter == 'All' ||
            status.contains(_selectedFilter.toLowerCase()) ||
            type.contains(_selectedFilter.toLowerCase());

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _updateAppointmentStatus(
      String appointmentId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/appointments/$appointmentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        _fetchAppointments(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment status updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to update appointment status');
      }
    } catch (e) {
      _showErrorDialog('Failed to update appointment: $e');
    }
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', appointment['_id'] ?? 'N/A'),
              _buildDetailRow('User Email', appointment['userEmail'] ?? 'N/A'),
              _buildDetailRow(
                  'Therapist Email', appointment['therapistEmail'] ?? 'N/A'),
              _buildDetailRow('Type', appointment['type'] ?? 'N/A'),
              _buildDetailRow('Status', appointment['status'] ?? 'N/A'),
              _buildDetailRow('Date', appointment['date'] ?? 'N/A'),
              _buildDetailRow('Time', appointment['time'] ?? 'N/A'),
              _buildDetailRow(
                  'Duration', '${appointment['duration'] ?? 'N/A'} minutes'),
              _buildDetailRow('Fee', '\$${appointment['fee'] ?? 'N/A'}'),
              if (appointment['meetingLink'] != null)
                _buildDetailRow('Meeting Link', appointment['meetingLink']),
              if (appointment['notes'] != null)
                _buildDetailRow('Notes', appointment['notes']),
              _buildDetailRow('Created', appointment['createdAt'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (appointment['status'] != 'Completed')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showStatusUpdateDialog(appointment);
              },
              child: const Text('Update Status'),
            ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog(Map<String, dynamic> appointment) {
    final List<String> statusOptions = ['Scheduled', 'Completed', 'Cancelled'];
    String selectedStatus = appointment['status'] ?? 'Scheduled';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Appointment Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Status: ${appointment['status']}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'New Status',
                border: OutlineInputBorder(),
              ),
              items: statusOptions.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                selectedStatus = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAppointmentStatus(appointment['_id'], selectedStatus);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'online':
        return Icons.video_call;
      case 'physical':
        return Icons.location_on;
      default:
        return Icons.event;
    }
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
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search appointments by user, therapist, or type...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter by',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _filterOptions.map((filter) {
                          return DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                          _filterAppointments();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchAppointments,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Appointments: ${_filteredAppointments.length}',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Appointments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredAppointments.isEmpty
                    ? const Center(
                        child: Text(
                          'No appointments found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = _filteredAppointments[index];
                          final status = appointment['status'] ?? 'Unknown';
                          final type = appointment['type'] ?? 'Unknown';

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(status),
                                child: Icon(
                                  _getTypeIcon(type),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                '${appointment['userEmail'] ?? 'Unknown User'} → ${appointment['therapistEmail'] ?? 'Unknown Therapist'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${appointment['date']} at ${appointment['time']}'),
                                  Text('Type: $type | Status: $status'),
                                  Text('Fee: \$${appointment['fee'] ?? 'N/A'}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.info),
                                onPressed: () =>
                                    _showAppointmentDetails(appointment),
                              ),
                              onTap: () => _showAppointmentDetails(appointment),
                            ),
                          );
                        },
                      ),
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
