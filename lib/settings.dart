import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/screens/settings/notifications_settings_screen.dart';

import 'package:myapp/screens/settings/language_settings_screen.dart';
import 'package:myapp/screens/settings/security_settings_screen.dart';
import 'package:myapp/screens/settings/about_screen.dart';
import 'package:myapp/screens/settings/support_screen.dart';
import 'package:myapp/screens/settings/payment_methods_screen.dart';

import 'package:myapp/screens/settings/change_password_screen.dart';
import 'package:myapp/login_page.dart';
import 'package:myapp/components/modern_bottom_nav.dart';
import 'package:myapp/new_home_page.dart';
import 'package:myapp/services/session_service.dart';
import 'package:myapp/screens/profile_edit_screen.dart';
import 'package:myapp/screens/theme_settings_screen.dart' as custom_theme;
import 'package:provider/provider.dart';
import 'package:myapp/providers/ThemeProvider.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;

  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String username = '';
  String email = '';
  String? profilePhoto;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/users/${widget.userId}/profile'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          username = userData['username'] ?? '';
          email = userData['email'] ?? '';
          profilePhoto = userData['profilePhoto'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        // Read image as bytes and convert to base64
        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);
        final mimeType = image.mimeType ?? 'image/jpeg';
        final dataUrl = 'data:$mimeType;base64,$base64Image';

        // Upload to server
        final response = await http.post(
          Uri.parse(
              'https://mindease-backend-production.up.railway.app/api/users/${widget.userId}/profile-photo'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'profilePhoto': dataUrl}),
        );

        if (response.statusCode == 200) {
          setState(() {
            profilePhoto = dataUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to upload profile photo');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ScreenWithBottomNav(
          currentIndex:
              2, // Settings is index 2 in the bottom nav (medication and meditation moved to home)
          userId: widget.userId,
          child: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.getBackgroundGradient(),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Custom App Bar
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    child: Row(
                      children: [
                        const SizedBox(width: AppTheme.spacingM),
                        Text(
                          'Settings',
                          style: AppTheme.headingLarge.copyWith(
                            color: themeProvider.getTextPrimary(),
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
                        // Profile Section
                        Container(
                          decoration: BoxDecoration(
                            color: themeProvider.getSurfaceColor(),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusL),
                            boxShadow: AppTheme.softShadow,
                          ),
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _pickAndUploadProfilePhoto,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: themeProvider
                                            .getPrimaryColor()
                                            .withOpacity(0.1),
                                        image: profilePhoto != null &&
                                                profilePhoto!.contains(',')
                                            ? DecorationImage(
                                                image: MemoryImage(
                                                  base64Decode(profilePhoto!
                                                      .split(',')[1]),
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: profilePhoto == null
                                          ? Icon(
                                              Icons.person,
                                              size: 30,
                                              color: themeProvider
                                                  .getPrimaryColor(),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color:
                                              themeProvider.getPrimaryColor(),
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username.isNotEmpty
                                          ? username
                                          : 'Loading...',
                                      style: AppTheme.headingSmall.copyWith(
                                        color: themeProvider.getTextPrimary(),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email.isNotEmpty ? email : 'Loading...',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: themeProvider.getTextSecondary(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingL),

                        // Settings Options
                        Container(
                          decoration: BoxDecoration(
                            color: themeProvider.getSurfaceColor(),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusL),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Column(
                            children: [
                              _buildSettingsTile(
                                icon: Icons.person_outline,
                                title: 'Update Profile',
                                subtitle: 'Edit your personal information',
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileEditScreen(
                                        userId: widget.userId,
                                        userDetails: {
                                          'username': username,
                                          'email': email,
                                        },
                                      ),
                                    ),
                                  );

                                  // Refresh user data if profile was updated
                                  if (result == true) {
                                    _loadUserData();
                                  }
                                },
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.lock_outline,
                                title: 'Change Password',
                                subtitle: 'Update your account password',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChangePasswordScreen(
                                              userId: widget.userId),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.payment,
                                title: 'Payment Methods',
                                subtitle: 'Manage your payment options',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PaymentMethodsScreen(
                                              userId: widget.userId),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.notifications,
                                title: 'Notifications',
                                subtitle: 'Configure notification preferences',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NotificationsSettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.palette_outlined,
                                title: 'Theme',
                                subtitle: 'Choose your preferred theme',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const custom_theme
                                          .ThemeSettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.language,
                                title: 'Language',
                                subtitle: 'Select your language',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LanguageSettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.security,
                                title: 'Security',
                                subtitle: 'Manage security settings',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SecuritySettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.info_outline,
                                title: 'About',
                                subtitle: 'App information and version',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AboutScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.help_outline,
                                title: 'Support',
                                subtitle: 'Get help and contact support',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SupportScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildSettingsTile(
                                icon: Icons.logout,
                                title: 'Logout',
                                subtitle: 'Sign out of your account',
                                onTap: () {
                                  _showLogoutDialog();
                                },
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
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout? You will need to sign in again to access your account.',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingL,
                  vertical: AppTheme.spacingM,
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _performLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Logout using SessionService (clears session and notifies backend)
      await SessionService.logout();

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);

        // Navigate to login screen and clear all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (error) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: themeProvider.getPrimaryColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Icon(
              icon,
              color: themeProvider.getPrimaryColor(),
              size: 24,
            ),
          ),
          title: Text(
            title,
            style: AppTheme.bodyLarge.copyWith(
              color: themeProvider.getTextPrimary(),
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: AppTheme.bodySmall.copyWith(
              color: themeProvider.getTextSecondary(),
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: themeProvider.getTextLight(),
          ),
          onTap: onTap,
        );
      },
    );
  }

  Widget _buildDivider() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Divider(
          height: 1,
          color: themeProvider.getBorderColor(),
          indent: AppTheme.spacingL,
          endIndent: AppTheme.spacingL,
        );
      },
    );
  }
}
