import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/user_appointments_screen.dart';
import 'package:myapp/screens/location_therapist_finder.dart';
import 'package:myapp/mood_tracking.dart';
import 'package:myapp/journaling.dart';
import 'package:myapp/ai_analysis_screen.dart';
import 'package:myapp/meditation_screen.dart';
import 'package:myapp/medication_view_screen.dart';
import 'package:myapp/components/modern_bottom_nav.dart';
import 'package:myapp/settings.dart';
import 'package:intl/intl.dart';
import 'package:myapp/services/session_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/ThemeProvider.dart';

class NewHomeScreen extends StatefulWidget {
  final String userId;

  const NewHomeScreen({super.key, required this.userId});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  Map<String, dynamic>? userDetails;
  List<dynamic> recentAppointments = [];
  List<Map<String, dynamic>> moodEntries = [];
  String selectedMood = '';
  bool isLoading = true;
  bool isLoadingMood = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await Future.wait([
        _fetchUserDetails(),
        _fetchRecentAppointments(),
        _fetchMoodEntries(),
      ]);
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load data. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/users/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          userDetails = responseData is Map
              ? (responseData['user'] ?? responseData)
              : responseData;
        });
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<void> _fetchRecentAppointments() async {
    try {
      // Get authentication headers with session token
      final headers = await SessionService.getAuthHeaders();

      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/appointments/user/${widget.userId}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> appointments = jsonDecode(response.body);
        setState(() {
          recentAppointments = appointments.take(3).toList();
        });
      } else {
        print('Failed to fetch appointments: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }

  Future<void> _fetchMoodEntries() async {
    try {
      // Get authentication headers with session token
      final headers = await SessionService.getAuthHeaders();

      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/mood/${widget.userId}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          moodEntries = data.cast<Map<String, dynamic>>();
        });
      } else {
        print('Failed to fetch mood entries: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching mood entries: $e');
    }
  }

  Future<void> _submitMood(String mood) async {
    if (isLoadingMood) return;

    setState(() {
      isLoadingMood = true;
    });

    try {
      // Get authentication headers with session token
      final headers = await SessionService.getAuthHeaders();

      final response = await http.post(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/mood/'),
        headers: headers,
        body: jsonEncode({
          'userId': widget.userId,
          'mood': mood,
          'note': '',
        }),
      );

      if (response.statusCode == 201) {
        // Refresh mood entries after successful submission
        await _fetchMoodEntries();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Mood "$mood" logged successfully!'),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to log mood. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error submitting mood: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoadingMood = false;
        selectedMood = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ScreenWithBottomNav(
          currentIndex: 0,
          userId: widget.userId,
          child: Scaffold(
            backgroundColor: themeProvider.getBackgroundColor(),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6B73FF),
                      Color(0xFF9B59B6),
                      Color(0xFF8E44AD),
                    ],
                  ),
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.psychology_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  const Text(
                    "MindEase",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              // Removed notification and settings icons as requested
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? _buildErrorState()
                    : _buildHomeContent(),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            errorMessage!,
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingL),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spacingL),
            _buildMoodTracking(),
            const SizedBox(height: AppTheme.spacingL),
            _buildQuickActions(),
            const SizedBox(height: AppTheme.spacingL),
            _buildMentalHealthTools(),
            const SizedBox(height: AppTheme.spacingL),
            _buildRecentAppointments(),
            const SizedBox(height: AppTheme.spacingL),
            _buildWellnessTips(),
            const SizedBox(height: 100), // Bottom padding for navigation
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final username = userDetails?['username'] ?? 'Friend';
        final currentHour = DateTime.now().hour;
        String greeting = 'Good Morning';
        String emoji = '🌅';

        if (currentHour >= 12 && currentHour < 17) {
          greeting = 'Good Afternoon';
          emoji = '☀️';
        } else if (currentHour >= 17) {
          greeting = 'Good Evening';
          emoji = '🌙';
        }

        final quotes = [
          "How are you feeling today? Remember, taking care of your mental health is just as important as your physical health. 💙",
          "Every day is a new opportunity to prioritize your well-being. You've got this! 🌟",
          "Your mental health matters. Take a moment to breathe and be kind to yourself. 🌸",
          "Progress, not perfection. Every small step towards better mental health counts. 🦋",
          "You are stronger than you think, braver than you feel, and more loved than you know. 💜",
        ];

        final quote = quotes[DateTime.now().day % quotes.length];

        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            gradient: themeProvider.getHeroGradient(),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$greeting,",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "$username!",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                quote,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTheme.headingMedium.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Book Appointment',
                Icons.calendar_today,
                AppTheme.primaryColor,
                () => _navigateToTherapistList(),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _buildActionCard(
                'Emergency Help',
                Icons.emergency,
                AppTheme.errorColor,
                () => _showEmergencyDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentalHealthTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mental Health Tools',
          style: AppTheme.headingMedium.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: AppTheme.spacingM),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppTheme.spacingM,
          mainAxisSpacing: AppTheme.spacingM,
          childAspectRatio: 1.2,
          children: [
            _buildToolCard(
              'Mood Tracking',
              Icons.mood,
              'Track your daily mood',
              AppTheme.successColor,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MoodTrackingScreen(),
                ),
              ),
            ),
            _buildToolCard(
              'Journaling',
              Icons.book,
              'Write your thoughts',
              AppTheme.warningColor,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JournalScreen(userId: widget.userId),
                ),
              ),
            ),
            _buildToolCard(
              'AI Analysis',
              Icons.psychology,
              'Get AI insights',
              Colors.blue,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AIAnalysisScreen(userId: widget.userId),
                ),
              ),
            ),
            _buildToolCard(
              'Meditation',
              Icons.self_improvement,
              'Guided meditation',
              AppTheme.primaryColor,
              () => _showMeditationFeatures(),
            ),
            _buildToolCard(
              'Medications',
              Icons.medication,
              'View prescriptions',
              Colors.red,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MedicationViewScreen(userId: widget.userId),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard(String title, IconData icon, String subtitle,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              title,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentAppointments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Appointments',
              style:
                  AppTheme.headingMedium.copyWith(color: AppTheme.textPrimary),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UserAppointmentsScreen(userId: widget.userId),
                ),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        recentAppointments.isEmpty
            ? _buildEmptyAppointments()
            : Column(
                children: recentAppointments
                    .map((appointment) => _buildAppointmentCard(appointment))
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildEmptyAppointments() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'No appointments yet',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Book your first appointment with a therapist',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatAppointmentDateTime(Map<String, dynamic> appointment) {
    try {
      // Handle different possible date field names and formats
      String? dateString = appointment['appointmentDate'] ??
          appointment['date'] ??
          appointment['appointmentDateTime'];

      if (dateString == null) {
        return 'Date not available';
      }

      // Parse the date string
      DateTime appointmentDate = DateTime.parse(dateString);

      // Format the date and time
      String formattedDate = DateFormat('MMM d, yyyy').format(appointmentDate);
      String formattedTime = DateFormat('h:mm a').format(appointmentDate);

      return '$formattedDate at $formattedTime';
    } catch (e) {
      print('Error formatting appointment date: $e');
      // Fallback to raw data if available
      return '${appointment['date'] ?? 'Date'} at ${appointment['time'] ?? 'Time'}';
    }
  }

  String _getTherapistDisplayName(Map<String, dynamic> appointment) {
    // Try to get therapist name from different possible fields
    String? therapistName = appointment['therapistName'] ??
        appointment['therapist']?['name'] ??
        appointment['therapist']?['username'];

    if (therapistName != null && therapistName.isNotEmpty) {
      return therapistName;
    }

    // Fallback to email if name is not available
    String? therapistEmail =
        appointment['therapistEmail'] ?? appointment['therapist']?['email'];

    if (therapistEmail != null && therapistEmail.isNotEmpty) {
      // Extract name part from email (before @)
      return therapistEmail.split('@').first.replaceAll('.', ' ').toUpperCase();
    }

    return 'Therapist';
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(
              appointment['type'] == 'online' ? Icons.videocam : Icons.person,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTherapistDisplayName(appointment),
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatAppointmentDateTime(appointment),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(appointment['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Text(
              appointment['status']?.toString().toUpperCase() ?? 'UNKNOWN',
              style: AppTheme.bodySmall.copyWith(
                color: _getStatusColor(appointment['status']),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'scheduled':
        return AppTheme.successColor;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildWellnessTips() {
    final tips = [
      'Take deep breaths when feeling anxious',
      'Practice gratitude daily',
      'Stay hydrated and get enough sleep',
      'Connect with friends and family',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wellness Tips',
          style: AppTheme.headingMedium.copyWith(color: AppTheme.textPrimary),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Text(
                  tips[DateTime.now().day % tips.length],
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emergency, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Text('Emergency Help'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'If you are in immediate danger or having thoughts of self-harm, please contact:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildEmergencyContact('🚨 Emergency Services', '911', 'tel:911'),
            _buildEmergencyContact(
                '💬 Crisis Text Line', 'Text HOME to 741741', 'sms:741741'),
            _buildEmergencyContact(
                '📞 National Suicide Prevention', '988', 'tel:988'),
            _buildEmergencyContact(
                '🌐 Crisis Chat',
                'suicidepreventionlifeline.org',
                'https://suicidepreventionlifeline.org/chat/'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
              ),
              child: const Text(
                '⚠️ You are not alone. Help is available 24/7.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(String title, String subtitle, String action) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          // Show confirmation dialog for emergency calls
          if (action.startsWith('tel:')) {
            final bool? confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.phone, color: AppTheme.errorColor),
                    const SizedBox(width: 8),
                    const Text('Confirm Emergency Call'),
                  ],
                ),
                content: Text(
                  'Are you sure you want to call $subtitle?\n\nThis will dial emergency services immediately.',
                  style: const TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Call Now'),
                  ),
                ],
              ),
            );

            if (confirmed != true) return;
          }

          try {
            final Uri uri = Uri.parse(action);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening $title...'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              throw 'Could not launch $action';
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Error: Could not open $title. Please dial manually.'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Copy Number',
                  textColor: Colors.white,
                  onPressed: () {
                    // Extract phone number from tel: URI
                    String phoneNumber = action.replaceFirst('tel:', '');
                    Clipboard.setData(ClipboardData(text: phoneNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
    );
  }

  void _showMeditationFeatures() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.self_improvement, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Meditation & Mindfulness'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMeditationOption(
                '🧘‍♀️ Breathing Exercise', '5-minute guided breathing', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeditationScreen(userId: widget.userId),
                ),
              );
            }),
            _buildMeditationOption(
                '🌊 Calm Sounds', 'Nature sounds for relaxation', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeditationScreen(userId: widget.userId),
                ),
              );
            }),
            _buildMeditationOption(
                '💭 Mindfulness Tips', 'Daily mindfulness practices', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeditationScreen(userId: widget.userId),
                ),
              );
            }),
            _buildMeditationOption(
                '😴 Sleep Stories', 'Bedtime relaxation stories', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeditationScreen(userId: widget.userId),
                ),
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildMeditationOption(
      String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _navigateToTherapistList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationTherapistFinder(
          userId: widget.userId,
        ),
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Notifications'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.blue),
              title: const Text('Appointment Reminder'),
              subtitle:
                  const Text('Your session with Dr. Smith is tomorrow at 2 PM'),
              trailing: const Text('1h ago'),
            ),
            ListTile(
              leading: const Icon(Icons.mood, color: Colors.green),
              title: const Text('Mood Check-in'),
              subtitle: const Text('How are you feeling today?'),
              trailing: const Text('3h ago'),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb, color: Colors.orange),
              title: const Text('Daily Tip'),
              subtitle: const Text('Try the 4-7-8 breathing technique'),
              trailing: const Text('1d ago'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _startBreathingExercise() {
    Navigator.pop(context); // Close meditation dialog first

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildBreathingExerciseDialog(),
    );
  }

  void _showCalmSounds() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🌊 Calm Sounds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.waves),
              title: const Text('Ocean Waves'),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _playSound('Ocean Waves'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.park),
              title: const Text('Forest Sounds'),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _playSound('Forest Sounds'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('Rain Drops'),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _playSound('Rain Drops'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMindfulnessTips() {
    final tips = [
      '🌱 Start your day with 5 minutes of mindful breathing',
      '🍃 Practice gratitude by listing 3 things you\'re thankful for',
      '🌸 Take mindful walks and notice your surroundings',
      '🧘‍♂️ Use the 5-4-3-2-1 grounding technique when anxious',
      '💫 Practice loving-kindness meditation before sleep',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('💭 Mindfulness Tips'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: tips
              .map((tip) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(tip),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSleepStories() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('😴 Sleep Stories'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Peaceful Garden'),
              subtitle: const Text('15 min • Relaxing nature story'),
              trailing: const Icon(Icons.play_arrow),
              onTap: () => _playSleepStory('Peaceful Garden'),
            ),
            ListTile(
              title: const Text('Mountain Retreat'),
              subtitle: const Text('20 min • Calming mountain journey'),
              trailing: const Icon(Icons.play_arrow),
              onTap: () => _playSleepStory('Mountain Retreat'),
            ),
            ListTile(
              title: const Text('Ocean Sunset'),
              subtitle: const Text('12 min • Peaceful beach setting'),
              trailing: const Icon(Icons.play_arrow),
              onTap: () => _playSleepStory('Ocean Sunset'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Breathing Exercise Dialog
  Widget _buildBreathingExerciseDialog() {
    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('🧘‍♀️ Breathing Exercise'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('4-7-8 Breathing Technique'),
              const SizedBox(height: 20),
              const Text('• Inhale for 4 counts'),
              const Text('• Hold for 7 counts'),
              const Text('• Exhale for 8 counts'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          '🧘‍♀️ Breathing exercise started! Follow the rhythm.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Start Exercise'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoodTracking() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeProvider.getPrimaryColor().withOpacity(0.1),
                themeProvider.getAccentColor().withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            border: Border.all(
              color: themeProvider.getPrimaryColor().withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mood,
                    color: themeProvider.getPrimaryColor(),
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Text(
                    'How are you feeling today?',
                    style: AppTheme.headingSmall.copyWith(
                      color: themeProvider.getTextPrimary(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Show mood selection or progress/graph based on entries count
              moodEntries.length < 3
                  ? _buildMoodSelectionWithProgress()
                  : _buildMoodGraphSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoodSelectionWithProgress() {
    return Column(
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track ${3 - moodEntries.length} more mood${3 - moodEntries.length == 1 ? '' : 's'} to see your trends',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      '${moodEntries.length}/3 moods tracked',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress circle
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      value: moodEntries.length / 3,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      strokeWidth: 3,
                    ),
                  ),
                  Text(
                    '${moodEntries.length}',
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),

        // Mood selection buttons
        _buildMoodSelectionButtons(),
      ],
    );
  }

  Widget _buildMoodSelectionButtons() {
    final moods = [
      {'emoji': '😊', 'label': 'Happy', 'color': Colors.green},
      {'emoji': '😌', 'label': 'Calm', 'color': Colors.blue},
      {'emoji': '😐', 'label': 'Neutral', 'color': Colors.grey},
      {'emoji': '😔', 'label': 'Sad', 'color': Colors.orange},
      {'emoji': '😰', 'label': 'Anxious', 'color': Colors.red},
    ];

    return Wrap(
      spacing: AppTheme.spacingS,
      runSpacing: AppTheme.spacingS,
      children: moods.map((mood) {
        final isSelected = selectedMood == mood['label'];
        final color = mood['color'] as Color;

        return GestureDetector(
          onTap: isLoadingMood
              ? null
              : () {
                  setState(() {
                    selectedMood = mood['label'] as String;
                  });
                  _submitMood(mood['label'] as String);
                },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoadingMood && isSelected)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  Text(
                    mood['emoji'] as String,
                    style: const TextStyle(fontSize: 20),
                  ),
                const SizedBox(width: AppTheme.spacingXS),
                Text(
                  mood['label'] as String,
                  style: AppTheme.bodyMedium.copyWith(
                    color: isSelected ? color : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMoodGraphSection() {
    return Column(
      children: [
        // Header with mood count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Your Mood Trends',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingS,
                vertical: AppTheme.spacingXS,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Text(
                '${moodEntries.length} entries',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),

        // Mood chart
        Container(
          height: 200,
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildMoodChart(),
        ),
        const SizedBox(height: AppTheme.spacingM),

        // Add new mood button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoadingMood ? null : () => _showMoodSelectionDialog(),
            icon: isLoadingMood
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(isLoadingMood ? 'Adding...' : 'Add Today\'s Mood'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoodChart() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (moodEntries.isEmpty) {
          return Center(
            child: Text(
              'No mood data available',
              style: TextStyle(color: themeProvider.getTextSecondary()),
            ),
          );
        }

        // Convert mood entries to chart data
        final data = _prepareMoodChartData();
        final chartData = data['chartData'] as List<Map<String, dynamic>>;
        final spots = data['spots'] as List<FlSpot>;

        return LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.withOpacity(0.2),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 &&
                        value.toInt() < chartData.length) {
                      final date = chartData[value.toInt()]['date'] as DateTime;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('M/d').format(date),
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    const moodLabels = [
                      'Anxious',
                      'Sad',
                      'Neutral',
                      'Calm',
                      'Happy'
                    ];
                    if (value.toInt() >= 0 &&
                        value.toInt() < moodLabels.length) {
                      return Text(
                        moodLabels[value.toInt()],
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: themeProvider.getBorderColor()),
            ),
            minX: 0,
            maxX: (chartData.length - 1).toDouble(),
            minY: 0,
            maxY: 4,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    themeProvider.getPrimaryColor().withOpacity(0.8),
                    themeProvider.getAccentColor().withOpacity(0.8),
                  ],
                ),
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: AppTheme.primaryColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      themeProvider.getPrimaryColor().withOpacity(0.2),
                      themeProvider.getPrimaryColor().withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _prepareMoodChartData() {
    // Get last 7 days of mood entries
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 6));

    // Create a map of mood values (1-5 scale for better chart display)
    const moodValues = {
      'Anxious': 1.0,
      'Sad': 2.0,
      'Neutral': 3.0,
      'Calm': 4.0,
      'Happy': 5.0,
    };

    // Prepare chart data
    final chartData = <Map<String, dynamic>>[];
    final spots = <FlSpot>[];

    // Use recent mood entries (limit to 7 for better display)
    final recentEntries = moodEntries.take(7).toList();

    if (recentEntries.isEmpty) {
      // Create sample neutral data if no entries
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        chartData.add({
          'date': date,
          'value': 3.0,
          'mood': 'Neutral',
        });
        spots.add(FlSpot(i.toDouble(), 3.0));
      }
    } else {
      // Add actual entries
      for (int i = 0; i < recentEntries.length; i++) {
        final entry = recentEntries[i];
        final mood = entry['mood'] ?? 'Neutral';
        final dateStr = entry['createdAt'] ??
            entry['date'] ??
            DateTime.now().toIso8601String();
        final date = DateTime.parse(dateStr);
        final value = moodValues[mood] ?? 3.0;

        chartData.add({
          'date': date,
          'value': value,
          'mood': mood,
        });
        spots.add(FlSpot(i.toDouble(), value));
      }

      // Fill remaining spots if less than 7 entries
      while (spots.length < 7) {
        final date = now.subtract(Duration(days: 7 - spots.length - 1));
        chartData.add({
          'date': date,
          'value': 3.0,
          'mood': 'Neutral',
        });
        spots.add(FlSpot(spots.length.toDouble(), 3.0));
      }
    }

    return {
      'chartData': chartData,
      'spots': spots,
    };
  }

  void _showMoodSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How are you feeling?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMoodSelectionButtons(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Play Sound Method
  void _playSound(String soundName) {
    Navigator.pop(context); // Close calm sounds dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎵 Playing $soundName... Enjoy the relaxing sounds!'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Play Sleep Story Method
  void _playSleepStory(String storyName) {
    Navigator.pop(context); // Close sleep stories dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('😴 Playing "$storyName"... Sweet dreams!'),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
