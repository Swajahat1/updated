import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/providers/ThemeProvider.dart';
import 'package:myapp/components/modern_bottom_nav.dart';

class UserAppointmentsScreen extends StatefulWidget {
  final String userId;
  final bool showBackButton;

  const UserAppointmentsScreen({
    Key? key,
    required this.userId,
    this.showBackButton = true, // Default to true for backward compatibility
  }) : super(key: key);

  @override
  _UserAppointmentsScreenState createState() => _UserAppointmentsScreenState();
}

class _UserAppointmentsScreenState extends State<UserAppointmentsScreen> {
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserAppointments();
  }

  Future<void> _fetchUserAppointments() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/appointments/user/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> appointmentData = jsonDecode(response.body);
        setState(() {
          appointments = appointmentData.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load appointments';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _launchMeetingLink(String meetingLink) async {
    try {
      final Uri url = Uri.parse(meetingLink);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch meeting link')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching meeting link: $e')),
      );
    }
  }

  void _copyMeetingLink(String meetingLink) {
    Clipboard.setData(ClipboardData(text: meetingLink));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Meeting link copied to clipboard!')),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rescheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'rescheduled':
        return Icons.update;
      default:
        return Icons.help;
    }
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final DateTime appointmentDate =
            DateTime.parse(appointment['appointmentDate']);
        final bool isOnline = appointment['meetingLink'] != null;
        final String status = appointment['status'] ?? 'scheduled';

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
          decoration: BoxDecoration(
            gradient: themeProvider.getCardGradient(),
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: AppTheme.softShadow,
            border: Border.all(
              color: themeProvider.getPrimaryColor().withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                      decoration: BoxDecoration(
                        gradient: isOnline
                            ? const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                              )
                            : const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOnline
                                ? Icons.videocam_rounded
                                : Icons.location_on_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Text(
                            isOnline ? 'Online Session' : 'Physical Session',
                            style: AppTheme.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingS,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                          color: _getStatusColor(status).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            size: 16,
                            color: _getStatusColor(status),
                          ),
                          const SizedBox(width: AppTheme.spacingXS),
                          Text(
                            status.toUpperCase(),
                            style: AppTheme.bodySmall.copyWith(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Appointment details
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingS),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusS),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, MMMM d, yyyy')
                                  .format(appointmentDate),
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingS),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusS),
                            ),
                            child: Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          Expanded(
                            child: Text(
                              '${DateFormat('h:mm a').format(appointmentDate)} (${appointment['duration']} minutes)',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (appointment['notes'] != null &&
                    appointment['notes'].isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                        color: AppTheme.accentColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingS),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Icon(
                            Icons.note_rounded,
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Expanded(
                          child: Text(
                            appointment['notes'],
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Meeting link section for online appointments
                if (isOnline && appointment['meetingLink'] != null) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingS),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusS),
                              ),
                              child: const Icon(
                                Icons.videocam_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Text(
                              'Google Meet Link',
                              style: AppTheme.bodyLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusM),
                                  boxShadow: AppTheme.softShadow,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () => _launchMeetingLink(
                                      appointment['meetingLink']),
                                  icon: const Icon(Icons.launch_rounded,
                                      size: 18),
                                  label: Text(
                                    'Join Meeting',
                                    style: AppTheme.buttonText.copyWith(
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.spacingM,
                                      vertical: AppTheme.spacingM,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusM),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusS),
                              ),
                              child: IconButton(
                                onPressed: () => _copyMeetingLink(
                                    appointment['meetingLink']),
                                icon: const Icon(Icons.copy_rounded,
                                    color: Colors.white),
                                tooltip: 'Copy Link',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ScreenWithBottomNav(
          currentIndex: 1, // Appointments is index 1 in the bottom nav
          userId: widget.userId,
          child: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.getBackgroundGradient(),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Modern App Bar
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppTheme.radiusXL),
                        bottomRight: Radius.circular(AppTheme.radiusXL),
                      ),
                      boxShadow: AppTheme.mediumShadow,
                    ),
                    child: Row(
                      children: [
                        if (widget.showBackButton) ...[
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back_ios,
                                color: Colors.white),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                        ],
                        Expanded(
                          child: Text(
                            "My Appointments",
                            style: AppTheme.headingMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.refresh_rounded,
                                color: Colors.white),
                            onPressed: () {
                              setState(() {
                                isLoading = true;
                                errorMessage = null;
                              });
                              _fetchUserAppointments();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content Area
                  Expanded(
                    child: isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.all(AppTheme.spacingL),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.cardGradient,
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radiusL),
                                    boxShadow: AppTheme.softShadow,
                                  ),
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryColor,
                                    strokeWidth: 3,
                                  ),
                                ),
                                const SizedBox(height: AppTheme.spacingL),
                                Text(
                                  'Loading appointments...',
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : errorMessage != null
                            ? Center(
                                child: Container(
                                  margin:
                                      const EdgeInsets.all(AppTheme.spacingL),
                                  padding:
                                      const EdgeInsets.all(AppTheme.spacingL),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.cardGradient,
                                    borderRadius:
                                        BorderRadius.circular(AppTheme.radiusL),
                                    boxShadow: AppTheme.softShadow,
                                    border: Border.all(
                                      color:
                                          AppTheme.errorColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(
                                            AppTheme.spacingM),
                                        decoration: BoxDecoration(
                                          color: AppTheme.errorColor
                                              .withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.radiusRound),
                                        ),
                                        child: Icon(
                                          Icons.error_outline_rounded,
                                          size: 48,
                                          color: AppTheme.errorColor,
                                        ),
                                      ),
                                      const SizedBox(height: AppTheme.spacingM),
                                      Text(
                                        errorMessage!,
                                        style: AppTheme.bodyLarge.copyWith(
                                          color: AppTheme.errorColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: AppTheme.spacingL),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.primaryGradient,
                                          borderRadius: BorderRadius.circular(
                                              AppTheme.radiusM),
                                          boxShadow: AppTheme.softShadow,
                                        ),
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              isLoading = true;
                                              errorMessage = null;
                                            });
                                            _fetchUserAppointments();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppTheme.spacingL,
                                              vertical: AppTheme.spacingM,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppTheme.radiusM),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.refresh_rounded,
                                                  color: Colors.white),
                                              const SizedBox(
                                                  width: AppTheme.spacingS),
                                              Text(
                                                'Retry',
                                                style: AppTheme.buttonText
                                                    .copyWith(
                                                        color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : appointments.isEmpty
                                ? Center(
                                    child: Container(
                                      margin: const EdgeInsets.all(
                                          AppTheme.spacingL),
                                      padding: const EdgeInsets.all(
                                          AppTheme.spacingXL),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.cardGradient,
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusL),
                                        boxShadow: AppTheme.softShadow,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(
                                                AppTheme.spacingL),
                                            decoration: BoxDecoration(
                                              gradient:
                                                  AppTheme.primaryGradient,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      AppTheme.radiusRound),
                                              boxShadow: AppTheme.softShadow,
                                            ),
                                            child: const Icon(
                                              Icons.calendar_month_rounded,
                                              size: 48,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: AppTheme.spacingL),
                                          Text(
                                            'No appointments found',
                                            style:
                                                AppTheme.headingSmall.copyWith(
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(
                                              height: AppTheme.spacingS),
                                          Text(
                                            'Book your first appointment to get started!',
                                            style: AppTheme.bodyMedium.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _fetchUserAppointments,
                                    color: AppTheme.primaryColor,
                                    backgroundColor: Colors.white,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppTheme.spacingM,
                                        vertical: AppTheme.spacingS,
                                      ),
                                      itemCount: appointments.length,
                                      itemBuilder: (context, index) {
                                        return _buildAppointmentCard(
                                            appointments[index]);
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
