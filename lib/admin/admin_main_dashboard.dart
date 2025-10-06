import 'package:flutter/material.dart';
import 'package:myapp/admin/user_management.dart';
import 'package:myapp/admin/therapist_management.dart';
import 'package:myapp/admin/appointment_management.dart';
import 'package:myapp/admin/payment_management.dart';
import 'package:myapp/admin/admin_login.dart';
import 'package:myapp/theme/app_theme.dart';
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
            gradient: AppTheme.primaryGradient,
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
              gradient: AppTheme.heroGradient,
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
      final usersResponse =
          await http.get(Uri.parse('http:// 192.168.2.102:3000/api/users'));

      // Fetch therapists count
      final therapistsResponse = await http
          .get(Uri.parse('http:// 192.168.2.102:3000/api/therapists'));

      // Fetch appointments count
      final appointmentsResponse = await http
          .get(Uri.parse('http:// 192.168.2.102:3000/api/appointments'));

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
            totalRevenue += (appointment['fee'] as num).toDouble();
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Cards
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStatCard(
                      title: 'Total Users',
                      value: '${_stats['totalUsers']}',
                      icon: Icons.people_outline,
                      color: const Color(0xFF4A90E2),
                    ),
                    _buildStatCard(
                      title: 'Active Therapists',
                      value: '${_stats['activeTherapists']}',
                      icon: Icons.psychology_outlined,
                      color: const Color(0xFF50C878),
                    ),
                    _buildStatCard(
                      title: 'Today\'s Appointments',
                      value: '${_stats['todayAppointments']}',
                      icon: Icons.calendar_today_outlined,
                      color: const Color(0xFFFF8C42),
                    ),
                    _buildStatCard(
                      title: 'Total Revenue',
                      value: '\$${_stats['totalRevenue'].toStringAsFixed(2)}',
                      icon: Icons.monetization_on_outlined,
                      color: const Color(0xFF9B59B6),
                    ),
                  ],
                ),
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: AppTheme.headingMedium.copyWith(
              color: const Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Block User',
                  icon: Icons.block_outlined,
                  color: const Color(0xFFE74C3C),
                  onTap: () {
                    // TODO: Quick block user
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Review Payments',
                  icon: Icons.payment_outlined,
                  color: const Color(0xFF27AE60),
                  onTap: () {
                    // TODO: Quick payment review
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
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
