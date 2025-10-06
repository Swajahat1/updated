import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:myapp/theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceColor,
                        foregroundColor: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Text(
                      'Support',
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  children: [
                    // Contact Support
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contact Support',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          Text(
                            'Need help? Our support team is here to assist you.',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          _buildContactOption(
                            Icons.email,
                            'Email Support',
                            'bscs2112134@szabistpk',
                            'Get help via email',
                            () => _launchEmail('support@mindease.com'),
                          ),
                          _buildContactOption(
                            Icons.phone,
                            'Phone Support',
                            '+92 300 1234567',
                            'Call us for immediate assistance',
                            () => _launchPhone('+923001234567'),
                          ),
                          _buildContactOption(
                            Icons.chat,
                            'Live Chat',
                            'Available 24/7',
                            'Chat with our support team',
                            () => _showLiveChatDialog(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingL),

                    // FAQ Section
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Frequently Asked Questions',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          _buildFAQItem(
                            'How do I book an appointment?',
                            'Navigate to the therapist directory, select a therapist, and choose an available time slot.',
                          ),
                          _buildFAQItem(
                            'How do I cancel an appointment?',
                            'Go to your appointments section and select the appointment you want to cancel.',
                          ),
                          _buildFAQItem(
                            'Is my data secure?',
                            'Yes, we use industry-standard encryption to protect your personal information.',
                          ),
                          _buildFAQItem(
                            'How do I change my password?',
                            'Go to Settings > Change Password and follow the instructions.',
                          ),
                          _buildFAQItem(
                            'Can I switch therapists?',
                            'Yes, you can browse and select different therapists at any time.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingL),

                    // Help Resources
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Help Resources',
                            style: AppTheme.headingSmall.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          _buildResourceItem(
                            Icons.book,
                            'User Guide',
                            'Learn how to use MindEase effectively',
                            () => _showUserGuide(context),
                          ),
                          _buildResourceItem(
                            Icons.video_library,
                            'Video Tutorials',
                            'Watch step-by-step tutorials',
                            () => _showVideoTutorials(context),
                          ),
                          _buildResourceItem(
                            Icons.forum,
                            'Community Forum',
                            'Connect with other users',
                            () => _launchUrl('https://community.mindease.com'),
                          ),
                          _buildResourceItem(
                            Icons.bug_report,
                            'Report a Bug',
                            'Help us improve the app',
                            () => _showBugReportDialog(context),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingL),

                    // Emergency Support
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        border: Border.all(
                          color: AppTheme.errorColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.emergency,
                                color: AppTheme.errorColor,
                                size: 24,
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                'Emergency Support',
                                style: AppTheme.headingSmall.copyWith(
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Text(
                            'If you are experiencing a mental health emergency, please contact:',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          _buildEmergencyContactOption(
                            context,
                            '🚨 Emergency Services',
                            '911',
                            'tel:911',
                          ),
                          _buildEmergencyContactOption(
                            context,
                            '📞 Crisis Helpline',
                            '988 (National Suicide Prevention)',
                            'tel:988',
                          ),
                          _buildEmergencyContactOption(
                            context,
                            '💬 Crisis Text Line',
                            'Text HOME to 741741',
                            'sms:741741',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactOption(IconData icon, String title, String subtitle,
      String description, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.spacingS),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.bodyLarge.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            description,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textLight,
      ),
      onTap: onTap,
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Text(
            answer,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResourceItem(
      IconData icon, String title, String description, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor,
        size: 24,
      ),
      title: Text(
        title,
        style: AppTheme.bodyLarge.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        description,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textLight,
      ),
      onTap: onTap,
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=MindEase Support Request',
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Widget _buildEmergencyContactOption(
      BuildContext context, String title, String subtitle, String action) {
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
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showLiveChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Chat'),
        content: const Text(
            'Live chat feature will be available soon. Please use email or phone support for now.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUserGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Guide'),
        content: const Text(
            'User guide feature coming soon. Please contact support for assistance.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showVideoTutorials(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Tutorials'),
        content: const Text(
            'Video tutorials will be available soon. Please contact support for help.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const Text(
            'Please email us at support@mindease.com with details about the bug you encountered.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
