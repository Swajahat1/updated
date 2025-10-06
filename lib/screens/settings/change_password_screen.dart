import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/services/session_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String userId;

  const ChangePasswordScreen({super.key, required this.userId});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog('New passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get authentication headers with session token
      final headers = await SessionService.getAuthHeaders();

      final response = await http.put(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/users/${widget.userId}/password'),
        headers: headers,
        body: jsonEncode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final errorData = jsonDecode(response.body);
        _showErrorDialog(errorData['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error: $e');
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
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
  }

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
                      'Change Password',
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Security Info Card
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusL),
                            boxShadow: AppTheme.softShadow,
                          ),
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          child: Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.all(AppTheme.spacingM),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusM),
                                ),
                                child: Icon(
                                  Icons.security,
                                  color: AppTheme.primaryColor,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Password Security',
                                      style: AppTheme.headingSmall.copyWith(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Use a strong password with at least 8 characters',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingL),

                        // Password Form
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusL),
                            boxShadow: AppTheme.softShadow,
                          ),
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Change Password',
                                style: AppTheme.headingSmall.copyWith(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingL),
                              _buildPasswordField(
                                controller: _currentPasswordController,
                                label: 'Current Password',
                                obscureText: _obscureCurrentPassword,
                                onToggleVisibility: () {
                                  setState(() {
                                    _obscureCurrentPassword =
                                        !_obscureCurrentPassword;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your current password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              _buildPasswordField(
                                controller: _newPasswordController,
                                label: 'New Password',
                                obscureText: _obscureNewPassword,
                                onToggleVisibility: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a new password';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              _buildPasswordField(
                                controller: _confirmPasswordController,
                                label: 'Confirm New Password',
                                obscureText: _obscureConfirmPassword,
                                onToggleVisibility: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your new password';
                                  }
                                  if (value != _newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppTheme.spacingXL),

                        // Change Password Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppTheme.spacingM),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusM),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Change Password',
                                    style: AppTheme.bodyLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(Icons.lock, color: AppTheme.primaryColor),
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: AppTheme.textSecondary,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: AppTheme.backgroundColor,
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
