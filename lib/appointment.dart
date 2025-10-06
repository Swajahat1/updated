import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class MyAppointmentsScreen extends StatefulWidget {
  // Add userId as a parameter to the constructor
  final String userId;

  const MyAppointmentsScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  _MyAppointmentsScreenState createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  // API base URL
  final String baseUrl =
      'https://mindease-backend-production.up.railway.app/api';

  // States
  bool _isLoading = false;
  List<Map<String, dynamic>> _appointments = [];

  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Fetch user appointments
  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/appointments/user/${widget.userId}'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _appointments = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        _showErrorSnackBar('Failed to load appointments');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Cancel appointment
  Future<void> _cancelAppointment(String appointmentId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/appointments/$appointmentId/cancel'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackBar('Appointment cancelled successfully');
        _fetchAppointments(); // Refresh appointment list
      } else {
        final Map<String, dynamic> error = json.decode(response.body);
        _showErrorSnackBar(error['message'] ?? 'Failed to cancel appointment');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Get headers without auth token
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }

  // Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Show success message
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Show confirmation dialog before cancelling
  void _showCancellationDialog(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
            'Are you sure you want to cancel your appointment with ${appointment['therapistId']['name']} on ${DateFormat('MMMM d, yyyy').format(DateTime.parse(appointment['appointmentDate']))} at ${DateFormat('h:mm a').format(DateTime.parse(appointment['appointmentDate']))}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelAppointment(appointment['_id']);
            },
            child: const Text('Yes, Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter appointments based on status
    final upcomingAppointments = _appointments
        .where((appointment) =>
            appointment['status'] != 'cancelled' &&
            appointment['status'] != 'completed' &&
            DateTime.parse(appointment['appointmentDate'])
                .isAfter(DateTime.now()))
        .toList();

    final pastAppointments = _appointments
        .where((appointment) =>
            appointment['status'] == 'completed' ||
            DateTime.parse(appointment['appointmentDate'])
                .isBefore(DateTime.now()))
        .toList();

    final cancelledAppointments = _appointments
        .where((appointment) => appointment['status'] == 'cancelled')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: Theme.of(context).primaryColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Upcoming Appointments Tab
                _buildAppointmentList(upcomingAppointments, canCancel: true),

                // Past Appointments Tab
                _buildAppointmentList(pastAppointments),

                // Cancelled Appointments Tab
                _buildAppointmentList(cancelledAppointments),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Pass userId to book appointment screen
          final result = await Navigator.pushNamed(
            context,
            '/book-appointment',
            arguments: {'userId': widget.userId},
          );
          if (result == true) {
            _fetchAppointments();
          }
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Build appointment list
  Widget _buildAppointmentList(List<Map<String, dynamic>> appointments,
      {bool canCancel = false}) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('No appointments found'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          final therapist = appointment['therapistId'];
          final appointmentDate =
              DateTime.parse(appointment['appointmentDate']);
          final bool isPast = appointmentDate.isBefore(DateTime.now());

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    radius: 25,
                    child: Text(
                      therapist['name'][0].toUpperCase(),
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  title: Text(
                    therapist['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Specialty: ${therapist['specialty']}'),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Text(DateFormat('EEEE, MMMM d, yyyy')
                              .format(appointmentDate)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 4),
                          Text(DateFormat('h:mm a').format(appointmentDate)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.timelapse, size: 16),
                          const SizedBox(width: 4),
                          Text('${appointment['duration']} minutes'),
                        ],
                      ),
                      if (appointment['status'] == 'rescheduled') ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Rescheduled',
                            style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isPast &&
                    canCancel &&
                    appointment['status'] != 'cancelled') ...[
                  const Divider(),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (appointment['meetingLink'] != null) ...[
                          TextButton.icon(
                            onPressed: () {
                              // Launch meeting link
                              // You would typically use url_launcher package here
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Joining meeting...')),
                              );
                            },
                            icon: const Icon(Icons.video_call,
                                color: Colors.green),
                            label: const Text('Join Session',
                                style: TextStyle(color: Colors.green)),
                          ),
                        ],
                        TextButton.icon(
                          onPressed: () => _showCancellationDialog(appointment),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Cancel',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
