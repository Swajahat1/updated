import 'package:flutter/material.dart';
import 'user_management.dart';
import 'therapist_management.dart';
import 'appointment_management.dart';
import 'payment_management.dart';
import 'admin_login.dart';
import 'theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminMainDashboard extends StatefulWidget {
  const AdminMainDashboard({super.key});

  @override
  _AdminMainDashboardState createState() => _AdminMainDashboardState();
}

class _AdminMainDashboardState extends State<AdminMainDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AdminOverviewScreen(),
    const UserManagementScreen(),
    const TherapistManagementScreen(),
    const AppointmentManagementScreen(),
    const PaymentManagementScreen(),
  ];

  final List<String> _titles = [
    'Dashboard Overview',
    'User Management',
    'Therapist Management',
    'Appointment Management',
    'Payment Management',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                // TODO: Show notifications
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: () => _logout(),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: _screens[_selectedIndex],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'MindEase Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Administrative Panel',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  index: 0,
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Users',
                  index: 1,
                ),
                _buildDrawerItem(
                  icon: Icons.psychology,
                  title: 'Therapists',
                  index: 2,
                ),
                _buildDrawerItem(
                  icon: Icons.calendar_today,
                  title: 'Appointments',
                  index: 3,
                ),
                _buildDrawerItem(
                  icon: Icons.payment,
                  title: 'Payments',
                  index: 4,
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                    // TODO: Navigate to settings
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  onTap: () {
                    // TODO: Navigate to help
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF1A237E) : Colors.grey[600],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF1A237E) : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF1A237E).withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminLoginScreen()),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  _AdminOverviewScreenState createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'activeTherapists': 0,
    'todayAppointments': 0,
    'totalRevenue': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
    try {
      // Fetch users count
      final usersResponse = await http.get(Uri.parse(
          'https://mindease-backend-production.up.railway.app/api/users'));

      // Fetch therapists count
      final therapistsResponse = await http.get(Uri.parse(
          'https://mindease-backend-production.up.railway.app/api/therapists'));

      // Fetch appointments count
      final appointmentsResponse = await http.get(Uri.parse(
          'https://mindease-backend-production.up.railway.app/api/appointments'));

      if (usersResponse.statusCode == 200 &&
          therapistsResponse.statusCode == 200 &&
          appointmentsResponse.statusCode == 200) {
        final users = json.decode(usersResponse.body) as List;
        final therapists = json.decode(therapistsResponse.body) as List;
        final appointments = json.decode(appointmentsResponse.body) as List;

        // Calculate today's appointments
        final today = DateTime.now();
        final todayAppointments = appointments.where((appointment) {
          if (appointment['appointmentDate'] != null) {
            final appointmentDate =
                DateTime.parse(appointment['appointmentDate']);
            return appointmentDate.year == today.year &&
                appointmentDate.month == today.month &&
                appointmentDate.day == today.day;
          }
          return false;
        }).length;

        // Calculate total revenue
        double totalRevenue = 0.0;
        for (var appointment in appointments) {
          if (appointment['fee'] != null) {
            totalRevenue +=
                double.tryParse(appointment['fee'].toString()) ?? 0.0;
          }
        }

        setState(() {
          _stats = {
            'totalUsers': users.length,
            'activeTherapists': therapists.length,
            'todayAppointments': todayAppointments,
            'totalRevenue': totalRevenue,
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                      boxShadow: AppTheme.mediumShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusM),
                              ),
                              child: const Icon(
                                Icons.dashboard,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Dashboard',
                                    style: AppTheme.headingMedium.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Welcome back! Here\'s what\'s happening with MindEase today.',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Statistics Cards
                  Text(
                    'Overview Statistics',
                    style: AppTheme.headingMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppTheme.spacingM,
                    mainAxisSpacing: AppTheme.spacingM,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard(
                        'Total Users',
                        _stats['totalUsers'].toString(),
                        Icons.people,
                        AppTheme.primaryColor,
                      ),
                      _buildStatCard(
                        'Active Therapists',
                        _stats['activeTherapists'].toString(),
                        Icons.psychology,
                        AppTheme.successColor,
                      ),
                      _buildStatCard(
                        'Today\'s Appointments',
                        _stats['todayAppointments'].toString(),
                        Icons.calendar_today,
                        AppTheme.warningColor,
                      ),
                      _buildStatCard(
                        'Total Revenue',
                        '\$${_stats['totalRevenue'].toStringAsFixed(2)}',
                        Icons.attach_money,
                        AppTheme.secondaryColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: AppTheme.headingMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          'Block User',
                          Icons.block,
                          AppTheme.errorColor,
                          () {
                            // Navigate to user management
                            // TODO: Implement quick block user
                          },
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: _buildQuickActionCard(
                          'Review Payments',
                          Icons.payment,
                          AppTheme.successColor,
                          () {
                            // Navigate to payment management
                            // TODO: Implement quick review payments
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.05), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Text(
                  value,
                  style: AppTheme.headingMedium.copyWith(
                    color: color,
                    fontSize: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
