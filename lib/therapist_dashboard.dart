import 'package:flutter/material.dart';
// import 'package:flutter_calendar_carousel/flutter_calendar_carousel.dart';
import 'package:flutter_calendar_carousel/classes/event.dart';
import 'package:intl/intl.dart';
import 'package:myapp/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/therapist_test_results.dart';

class TherapistDashboard extends StatefulWidget {
  final String therapistId;

  const TherapistDashboard({Key? key, required this.therapistId})
      : super(key: key);

  @override
  State<TherapistDashboard> createState() => _TherapistDashboardState();
}

class _TherapistDashboardState extends State<TherapistDashboard> {
  int _selectedIndex = 0;
  DateTime _currentDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // Dynamic data
  List<Patient> _patients = [];
  List<Appointment> _todayAppointments = [];
  Map<String, dynamic>? _therapistData;
  bool _isLoadingPatients = true;
  bool _isLoadingAppointments = true;
  bool _isLoadingTherapist = true;
  String? _patientsError;
  String? _appointmentsError;
  String? _therapistError;

  final List<Task> _tasks = [
    Task(
        id: 1,
        title: 'Complete patient notes',
        deadline: DateTime.now(),
        isCompleted: false),
    Task(
        id: 2,
        title: 'Prepare for group therapy session',
        deadline: DateTime.now().add(const Duration(days: 1)),
        isCompleted: false),
    Task(
        id: 3,
        title: 'Review treatment plans',
        deadline: DateTime.now().add(const Duration(days: 2)),
        isCompleted: false),
    Task(
        id: 4,
        title: 'Insurance paperwork',
        deadline: DateTime.now().add(const Duration(days: 3)),
        isCompleted: true),
  ];

  @override
  void initState() {
    super.initState();
    _fetchTherapistData();
    _fetchPatients();
    _fetchAppointments();
  }

  Future<void> _fetchTherapistData() async {
    setState(() {
      _isLoadingTherapist = true;
      _therapistError = null;
    });
    try {
      final response = await http.get(Uri.parse(
          'http:// 192.168.2.102:3000/api/therapists/${widget.therapistId}'));
      if (response.statusCode == 200) {
        setState(() {
          _therapistData = json.decode(response.body);
        });
      } else {
        setState(() {
          _therapistError =
              'Failed to load therapist data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _therapistError = 'Error fetching therapist data: $e';
      });
    } finally {
      setState(() {
        _isLoadingTherapist = false;
      });
    }
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoadingPatients = true;
      _patientsError = null;
    });
    try {
      final response = await http.get(Uri.parse(
          'http:// 192.168.2.102:3000/api/appointments/therapist/${widget.therapistId}'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Convert appointment data to patient data
        Map<String, Patient> uniquePatients = {};

        for (var appointment in data) {
          String patientName = appointment['patientName'] ?? 'Unknown';
          String patientEmail = appointment['patientEmail'] ?? '';

          if (!uniquePatients.containsKey(patientEmail)) {
            // Convert string ID to int hash for Patient model compatibility
            int patientId =
                (appointment['id']?.toString() ?? '0').hashCode.abs();
            uniquePatients[patientEmail] = Patient(
              id: patientId,
              name: patientName,
              age: 25, // Default age since not provided by API
              nextAppointment: DateTime.tryParse(
                      appointment['appointmentDate']?.toString() ?? '') ??
                  DateTime.now(),
              progress: 0.7, // Default progress
            );
          }
        }

        setState(() {
          _patients = uniquePatients.values.toList();
        });
      } else {
        setState(() {
          _patientsError =
              'Failed to load patients: [38;5;1m${response.statusCode}[0m';
        });
      }
    } catch (e) {
      setState(() {
        _patientsError = 'Error fetching patients: $e';
      });
    } finally {
      setState(() {
        _isLoadingPatients = false;
      });
    }
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoadingAppointments = true;
      _appointmentsError = null;
    });
    try {
      final response = await http.get(Uri.parse(
          'https://mindease-backend-production.up.railway.app/api/appointments/therapist/${widget.therapistId}'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _todayAppointments =
              data.map((item) => Appointment.fromJson(item)).toList();
        });
      } else {
        setState(() {
          _appointmentsError =
              'Failed to load appointments: [38;5;1m${response.statusCode}[0m';
        });
      }
    } catch (e) {
      setState(() {
        _appointmentsError = 'Error fetching appointments: $e';
      });
    } finally {
      setState(() {
        _isLoadingAppointments = false;
      });
    }
  }

  void _showPatientDetails(Patient patient) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Patient Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Name: ${patient.name}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Age: ${patient.age}'),
                SizedBox(height: 8),
                Text('Patient ID: ${patient.id}'),
                SizedBox(height: 8),
                Text(
                    'Next Appointment: ${_dateFormat.format(patient.nextAppointment)}'),
                SizedBox(height: 8),
                Text(
                    'Progress: ${(patient.progress * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _scheduleAppointment(patient);
              },
              child: Text('Schedule Appointment'),
            ),
          ],
        );
      },
    );
  }

  void _scheduleAppointment(Patient patient) {
    // TODO: Implement appointment scheduling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Appointment scheduling for ${patient.name} - Coming soon!')),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.notifications, color: Colors.blue),
              SizedBox(width: 8),
              Text('Notifications'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView(
              children: [
                _buildNotificationItem(
                  'New appointment booked',
                  'wajahat@gmail.com has booked an online session for tomorrow',
                  Icons.calendar_today,
                  Colors.green,
                ),
                _buildNotificationItem(
                  'Appointment reminder',
                  'You have 3 appointments scheduled for today',
                  Icons.access_time,
                  Colors.orange,
                ),
                _buildNotificationItem(
                  'Patient message',
                  'John Doe sent you a message about their progress',
                  Icons.message,
                  Colors.blue,
                ),
                _buildNotificationItem(
                  'System update',
                  'New features available in the therapist portal',
                  Icons.system_update,
                  Colors.purple,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('All notifications marked as read')),
                );
              },
              child: Text('Mark All Read'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(
      String title, String message, IconData icon, Color color) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(message),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opened: $title')),
          );
        },
      ),
    );
  }

  void _showProfile() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.person, color: Colors.teal),
              SizedBox(width: 8),
              Text('Profile'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.teal.withOpacity(0.1),
                    child: Icon(Icons.person, size: 50, color: Colors.teal),
                  ),
                ),
                SizedBox(height: 16),
                _buildProfileRow(
                    'Name', _therapistData?['name'] ?? 'Loading...'),
                _buildProfileRow(
                    'Specialty', _therapistData?['specialty'] ?? 'Loading...'),
                _buildProfileRow('Experience',
                    '${_therapistData?['experience'] ?? 0} years'),
                _buildProfileRow(
                    'Location', _therapistData?['location'] ?? 'Loading...'),
                _buildProfileRow(
                    'Rating', '${_therapistData?['rating'] ?? 0}/5'),
                _buildProfileRow(
                    'Hourly Rate', '\$${_therapistData?['hourlyRate'] ?? 0}'),
                _buildProfileRow(
                    'Email', _therapistData?['email'] ?? 'Loading...'),
                _buildProfileRow(
                    'Phone', _therapistData?['phone'] ?? 'Loading...'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Edit profile - Coming soon!')),
                );
              },
              child: Text('Edit Profile'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.settings, color: Colors.grey[700]),
              SizedBox(width: 8),
              Text('Settings'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView(
              children: [
                _buildSettingItem(
                  'Account Settings',
                  'Manage your account information',
                  Icons.account_circle,
                  () => _showAccountSettings(),
                ),
                _buildSettingItem(
                  'Notification Preferences',
                  'Configure notification settings',
                  Icons.notifications_outlined,
                  () => _showNotificationSettings(),
                ),
                _buildSettingItem(
                  'Privacy & Security',
                  'Manage privacy and security settings',
                  Icons.security,
                  () => _showPrivacySettings(),
                ),
                _buildSettingItem(
                  'Availability Settings',
                  'Set your working hours and availability',
                  Icons.schedule,
                  () => _showAvailabilitySettings(),
                ),
                _buildSettingItem(
                  'Payment Settings',
                  'Manage payment methods and rates',
                  Icons.payment,
                  () => _showPaymentSettings(),
                ),
                _buildSettingItem(
                  'App Preferences',
                  'Customize app appearance and behavior',
                  Icons.tune,
                  () => _showAppPreferences(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingItem(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.teal),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showHelpSupport() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.help, color: Colors.blue),
              SizedBox(width: 8),
              Text('Help & Support'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            height: 350,
            child: ListView(
              children: [
                _buildHelpItem(
                  'Getting Started Guide',
                  'Learn how to use the therapist portal',
                  Icons.school,
                  () => _showGettingStarted(),
                ),
                _buildHelpItem(
                  'FAQ',
                  'Frequently asked questions',
                  Icons.quiz,
                  () => _showFAQ(),
                ),
                _buildHelpItem(
                  'Contact Support',
                  'Get help from our support team',
                  Icons.support_agent,
                  () => _contactSupport(),
                ),
                _buildHelpItem(
                  'Report a Bug',
                  'Report technical issues',
                  Icons.bug_report,
                  () => _reportBug(),
                ),
                _buildHelpItem(
                  'Feature Request',
                  'Suggest new features',
                  Icons.lightbulb,
                  () => _featureRequest(),
                ),
                _buildHelpItem(
                  'Privacy Policy',
                  'Read our privacy policy',
                  Icons.privacy_tip,
                  () => _showPrivacyPolicy(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  // Placeholder methods for settings
  void _showAccountSettings() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Account Settings - Coming soon!')),
    );
  }

  void _showNotificationSettings() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification Settings - Coming soon!')),
    );
  }

  void _showPrivacySettings() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Privacy Settings - Coming soon!')),
    );
  }

  void _showAvailabilitySettings() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Availability Settings - Coming soon!')),
    );
  }

  void _showPaymentSettings() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Settings - Coming soon!')),
    );
  }

  void _showAppPreferences() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('App Preferences - Coming soon!')),
    );
  }

  // Placeholder methods for help & support
  void _showGettingStarted() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Getting Started Guide - Coming soon!')),
    );
  }

  void _showFAQ() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('FAQ - Coming soon!')),
    );
  }

  void _contactSupport() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Contact Support - Coming soon!')),
    );
  }

  void _reportBug() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bug Report - Coming soon!')),
    );
  }

  void _featureRequest() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feature Request - Coming soon!')),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Privacy Policy - Coming soon!')),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppTheme.radiusL),
              topRight: Radius.circular(AppTheme.radiusL),
            ),
          ),
          padding: EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: AppTheme.spacingL),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: AppTheme.spacingL),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAction(
                    icon: Icons.person_add,
                    title: 'Add Patient',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement add patient
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.event_note,
                    title: 'Schedule\nAppointment',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement schedule appointment
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.assignment_add,
                    title: 'Add Task',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement add task
                    },
                  ),
                ],
              ),
              SizedBox(height: AppTheme.spacingL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            SizedBox(height: AppTheme.spacingS),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppTheme.spacingS,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(AppTheme.spacingXS),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        onTap: onTap ??
            () {
              setState(() {
                _selectedIndex = index;
              });
              Navigator.pop(context);
            },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Therapist Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: EdgeInsets.only(right: AppTheme.spacingXS),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(AppTheme.spacingXS),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(Icons.assessment, color: Colors.white),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TherapistTestResultsScreen(
                      therapistId: widget.therapistId,
                    ),
                  ),
                );
              },
              tooltip: 'View Patient Test Results',
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: AppTheme.spacingXS),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(AppTheme.spacingXS),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(Icons.notifications, color: Colors.white),
              ),
              onPressed: () {
                _showNotifications();
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: AppTheme.spacingS),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(AppTheme.spacingXS),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(Icons.person, color: Colors.white),
              ),
              onPressed: () {
                _showProfile();
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradient,
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacingXS),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppTheme.primaryColor,
                        child:
                            Icon(Icons.person, size: 30, color: Colors.white),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingS),
                    Text(
                      _therapistData?['name'] ?? 'Loading...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _therapistData?['specialty'] ?? 'Loading...',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(
                icon: Icons.dashboard,
                title: 'Dashboard',
                index: 0,
                isSelected: _selectedIndex == 0,
              ),
              _buildDrawerItem(
                icon: Icons.people,
                title: 'Patients',
                index: 1,
                isSelected: _selectedIndex == 1,
              ),
              _buildDrawerItem(
                icon: Icons.calendar_today,
                title: 'Appointments',
                index: 2,
                isSelected: _selectedIndex == 2,
              ),
              _buildDrawerItem(
                icon: Icons.assignment,
                title: 'Tasks',
                index: 3,
                isSelected: _selectedIndex == 3,
              ),
              Divider(color: AppTheme.textLight.withOpacity(0.3)),
              _buildDrawerItem(
                icon: Icons.settings,
                title: 'Settings',
                index: 4,
                isSelected: _selectedIndex == 4,
              ),
              _buildDrawerItem(
                icon: Icons.help,
                title: 'Help & Support',
                index: 5,
                isSelected: false,
                onTap: () {
                  Navigator.pop(context);
                  _showHelpSupport();
                },
              ),
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Logout',
                index: -1,
                isSelected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _selectedIndex > 3 ? 0 : _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          selectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Patients',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'Tasks',
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            _showAddOptions();
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildPatientsView();
      case 2:
        return _buildAppointmentsView();
      case 3:
        return _buildTasksView();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              padding: EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _therapistData != null
                        ? 'Welcome back, ${_therapistData!['name']}'
                        : 'Welcome back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: AppTheme.spacingXS),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppTheme.spacingL),

            // Overview Cards
            _isLoadingPatients || _isLoadingAppointments
                ? Center(
                    child: Container(
                      padding: EdgeInsets.all(AppTheme.spacingXL),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor),
                      ),
                    ),
                  )
                : _buildOverviewCards(),

            SizedBox(height: AppTheme.spacingL),

            // Today's Appointments
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Today's Appointments",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingM,
                            vertical: AppTheme.spacingS,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex =
                                    2; // Switch to appointments view
                              });
                            },
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    if (_isLoadingAppointments)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.spacingL),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor),
                          ),
                        ),
                      )
                    else if (_appointmentsError != null)
                      Container(
                        padding: EdgeInsets.all(AppTheme.spacingM),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: Text(
                          _appointmentsError!,
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else if (_todayAppointments.isEmpty)
                      Container(
                        padding: EdgeInsets.all(AppTheme.spacingL),
                        decoration: BoxDecoration(
                          color: AppTheme.textLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 48,
                              color: AppTheme.textLight,
                            ),
                            SizedBox(height: AppTheme.spacingS),
                            Text(
                              'No appointments for today.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ..._todayAppointments.map(
                          (appointment) => _buildAppointmentItem(appointment)),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppTheme.spacingL),

            // Calendar Card
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacingL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: AppTheme.spacingM),
                    // SizedBox(
                    //   height: 300,
                    //   child: CalendarCarousel<Event>(
                    //     onDayPressed: (date, events) {
                    //       setState(() {
                    //         _currentDate = date;
                    //       });
                    //     },
                    //     weekendTextStyle: const TextStyle(color: Colors.red),
                    //     thisMonthDayBorderColor: Colors.grey,
                    //     daysHaveCircularBorder: true,
                    //     showOnlyCurrentMonthDate: false,
                    //     weekFormat: false,
                    //     height: 300.0,
                    //     selectedDateTime: _currentDate,
                    //     selectedDayButtonColor: Colors.teal,
                    //     todayButtonColor: Colors.teal.withOpacity(0.3),
                    //     todayBorderColor: Colors.teal,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tasks Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Tasks',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const Divider(),
                    ..._tasks
                        .where((task) => !task.isCompleted)
                        .take(3)
                        .map((task) => _buildTaskItem(task)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Patient Progress Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Patient Progress',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_isLoadingPatients)
                      const Center(child: CircularProgressIndicator())
                    else if (_patientsError != null)
                      Text(_patientsError!,
                          style: const TextStyle(color: Colors.red))
                    else if (_patients.isEmpty)
                      const Text('No patients found.')
                    else
                      ..._patients
                          .take(3)
                          .map((patient) => _buildPatientProgressItem(patient)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppTheme.spacingM,
      mainAxisSpacing: AppTheme.spacingM,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildOverviewCard(
          title: 'Patients',
          value: _isLoadingPatients ? '...' : '${_patients.length}',
          icon: Icons.people,
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.primaryLight],
          ),
        ),
        _buildOverviewCard(
          title: 'Appointments',
          value:
              _isLoadingAppointments ? '...' : '${_todayAppointments.length}',
          icon: Icons.calendar_today,
          gradient: LinearGradient(
            colors: [AppTheme.secondaryColor, AppTheme.secondaryLight],
          ),
        ),
        _buildOverviewCard(
          title: 'Tasks',
          value: '${_tasks.where((task) => !task.isCompleted).length}',
          icon: Icons.assignment,
          gradient: LinearGradient(
            colors: [AppTheme.warningColor, Color(0xFFFBBF24)],
          ),
        ),
        _buildOverviewCard(
          title: 'Completed',
          value: '${_tasks.where((task) => task.isCompleted).length}',
          icon: Icons.check_circle,
          gradient: LinearGradient(
            colors: [AppTheme.successColor, Color(0xFF34D399)],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required LinearGradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
            ),
            SizedBox(height: AppTheme.spacingS),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: AppTheme.spacingXS),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(Appointment appointment) {
    final bool isOnline = appointment.meetingLink != null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOnline ? Icons.video_call : Icons.location_on,
                    color: isOnline ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${appointment.time} | ${appointment.duration} mins',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        isOnline ? 'Online Session' : 'Physical Session',
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'details') {
                      _showAppointmentDetails(appointment);
                    } else if (value == 'join' &&
                        appointment.meetingLink != null) {
                      _launchMeetingLink(appointment.meetingLink!);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info, size: 16),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    if (appointment.meetingLink != null)
                      const PopupMenuItem<String>(
                        value: 'join',
                        child: Row(
                          children: [
                            Icon(Icons.video_call,
                                size: 16, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Join Meeting'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (appointment.meetingLink != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.video_call, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Meeting Link Available',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          _launchMeetingLink(appointment.meetingLink!),
                      child: const Text('Join', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                appointment.meetingLink != null
                    ? Icons.video_call
                    : Icons.location_on,
                color: appointment.meetingLink != null
                    ? Colors.green
                    : Colors.orange,
              ),
              const SizedBox(width: 8),
              Text('Appointment Details'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Patient', appointment.patientName),
                _buildDetailRow('Time', appointment.time),
                _buildDetailRow('Duration', '${appointment.duration} minutes'),
                _buildDetailRow(
                    'Type',
                    appointment.meetingLink != null
                        ? 'Online Session'
                        : 'Physical Session'),
                _buildDetailRow('Status', appointment.status.toUpperCase()),
                if (appointment.notes != null && appointment.notes!.isNotEmpty)
                  _buildDetailRow('Notes', appointment.notes!),
                if (appointment.patientPhone != null)
                  _buildDetailRow('Patient Phone', appointment.patientPhone!),
                if (appointment.patientEmail != null)
                  _buildDetailRow('Patient Email', appointment.patientEmail!),
                if (appointment.meetingLink != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.video_call, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Google Meet Link:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          appointment.meetingLink!,
                          style: const TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            if (appointment.meetingLink != null)
              TextButton.icon(
                onPressed: () => _launchMeetingLink(appointment.meetingLink!),
                icon: const Icon(Icons.video_call),
                label: const Text('Join Meeting'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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

  Future<void> _launchMeetingLink(String meetingLink) async {
    try {
      final Uri url = Uri.parse(meetingLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch meeting link')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching meeting link: $e')),
        );
      }
    }
  }

  Widget _buildTaskItem(Task task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: task.isCompleted,
            onChanged: (value) {
              setState(() {
                task.isCompleted = value ?? false;
              });
            },
            activeColor: Colors.teal,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Due: ${_dateFormat.format(task.deadline)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPatientProgressItem(Patient patient) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Text(
                  patient.name.substring(0, 1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Next Appointment: ${_dateFormat.format(patient.nextAppointment)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: patient.progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(patient.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsView() {
    if (_isLoadingPatients) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_patientsError != null) {
      return Center(
          child:
              Text(_patientsError!, style: const TextStyle(color: Colors.red)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final patient = _patients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: Colors.teal,
              child: Text(
                patient.name.substring(0, 1),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              patient.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Age: ${patient.age}'),
                Text(
                    'Next appointment: ${_dateFormat.format(patient.nextAppointment)}'),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showPatientDetails(patient);
            },
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsView() {
    if (_isLoadingAppointments) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_appointmentsError != null) {
      return Center(
          child: Text(_appointmentsError!,
              style: const TextStyle(color: Colors.red)));
    }
    return Column(
      children: [
        // Calendar at the top
        // SizedBox(
        //   height: 350,
        //   child: CalendarCarousel<Event>(
        //     onDayPressed: (date, events) {
        //       setState(() {
        //         _currentDate = date;
        //       });
        //     },
        //     weekendTextStyle: const TextStyle(color: Colors.red),
        //     thisMonthDayBorderColor: Colors.grey,
        //     daysHaveCircularBorder: true,
        //     showOnlyCurrentMonthDate: false,
        //     weekFormat: false,
        //     height: 350.0,
        //     selectedDateTime: _currentDate,
        //     selectedDayButtonColor: Colors.teal,
        //     todayButtonColor: Colors.teal.withOpacity(0.3),
        //     todayBorderColor: Colors.teal,
        //     headerTextStyle: const TextStyle(
        //       fontSize: 20,
        //       fontWeight: FontWeight.bold,
        //       color: Colors.teal,
        //     ),
        //   ),
        // ),

        // Appointments for selected date
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointments for ${DateFormat('MMMM d, yyyy').format(_currentDate)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _todayAppointments.length,
                    itemBuilder: (context, index) {
                      final appointment = _todayAppointments[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                appointment.time.substring(0, 2),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            appointment.patientName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                  '${appointment.time} - ${appointment.duration} mins'),
                              Text(appointment.type),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {},
                              ),
                            ],
                          ),
                          onTap: () {
                            _showAppointmentDetails(appointment);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Completed'),
            ],
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
          ),
          Expanded(
            child: TabBarView(
              children: [
                // Pending Tasks
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.where((task) => !task.isCompleted).length,
                  itemBuilder: (context, index) {
                    final task = _tasks
                        .where((task) => !task.isCompleted)
                        .toList()[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (value) {
                            setState(() {
                              task.isCompleted = value ?? false;
                            });
                          },
                          activeColor: Colors.teal,
                        ),
                        title: Text(
                          task.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Due: ${_dateFormat.format(task.deadline)}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Completed Tasks
                ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tasks.where((task) => task.isCompleted).length,
                  itemBuilder: (context, index) {
                    final task = _tasks
                        .where((task) => task.isCompleted)
                        .toList()[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (value) {
                            setState(() {
                              task.isCompleted = value ?? false;
                            });
                          },
                          activeColor: Colors.teal,
                        ),
                        title: Text(
                          task.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Completed'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {},
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Models
class Patient {
  final int id;
  final String name;
  final int age;
  final DateTime nextAppointment;
  final double progress;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.nextAppointment,
    required this.progress,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] ?? json['_id'] ?? 0,
      name: json['name'] ?? '',
      age: json['age'] ?? 0,
      nextAppointment: DateTime.parse(json['nextAppointment']),
      progress: (json['progress'] is int)
          ? (json['progress'] as int).toDouble()
          : (json['progress'] ?? 0.0),
    );
  }
}

class Appointment {
  final int id;
  final String patientName;
  final String time;
  final int duration;
  final String type;
  final String? meetingLink;
  final String? notes;
  final String status;
  final String? patientPhone;
  final String? patientEmail;

  Appointment({
    required this.id,
    required this.patientName,
    required this.time,
    required this.duration,
    required this.type,
    this.meetingLink,
    this.notes,
    this.status = 'scheduled',
    this.patientPhone,
    this.patientEmail,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    // Convert string ID to int hash for model compatibility
    int appointmentId = 0;
    if (json['id'] != null) {
      appointmentId =
          json['id'] is int ? json['id'] : json['id'].toString().hashCode.abs();
    } else if (json['_id'] != null) {
      appointmentId = json['_id'] is int
          ? json['_id']
          : json['_id'].toString().hashCode.abs();
    }

    return Appointment(
      id: appointmentId,
      patientName: json['patientName'] ?? '',
      time: json['time'] ?? '',
      duration: json['duration'] ?? 0,
      type: json['type'] ?? '',
      meetingLink: json['meetingLink'],
      notes: json['notes'],
      status: json['status'] ?? 'scheduled',
      patientPhone: json['patientPhone'],
      patientEmail: json['patientEmail'],
    );
  }
}

class Task {
  final int id;
  final String title;
  final DateTime deadline;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.deadline,
    required this.isCompleted,
  });
}
