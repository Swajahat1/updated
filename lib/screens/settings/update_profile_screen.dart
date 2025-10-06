import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:myapp/theme/app_theme.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String userId;

  const UpdateProfileScreen({super.key, required this.userId});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  File? _profileImage;
  String? _currentImageUrl;

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
            'https://mindease-backend-production.up.railway.app/api/users/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        setState(() {
          _nameController.text = userData['username'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _currentImageUrl = userData['profileImage'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Failed to load user data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/users/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        _showErrorDialog('Failed to update profile');
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
                      'Update Profile',
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Profile Image Section
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusL),
                                  boxShadow: AppTheme.softShadow,
                                ),
                                padding:
                                    const EdgeInsets.all(AppTheme.spacingL),
                                child: Column(
                                  children: [
                                    GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          border: Border.all(
                                            color: AppTheme.primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        child: _profileImage != null
                                            ? ClipOval(
                                                child: Image.file(
                                                  _profileImage!,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : _currentImageUrl != null
                                                ? ClipOval(
                                                    child: Image.network(
                                                      _currentImageUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const Icon(
                                                        Icons.person,
                                                        size: 60,
                                                        color: AppTheme
                                                            .primaryColor,
                                                      ),
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.person,
                                                    size: 60,
                                                    color:
                                                        AppTheme.primaryColor,
                                                  ),
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacingM),
                                    TextButton.icon(
                                      onPressed: _pickImage,
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Change Photo'),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppTheme.spacingL),

                              // Form Fields
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusL),
                                  boxShadow: AppTheme.softShadow,
                                ),
                                padding:
                                    const EdgeInsets.all(AppTheme.spacingL),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Personal Information',
                                      style: AppTheme.headingSmall.copyWith(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacingL),
                                    _buildTextField(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      icon: Icons.person,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppTheme.spacingM),
                                    _buildTextField(
                                      controller: _emailController,
                                      label: 'Email',
                                      icon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!value.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppTheme.spacingM),
                                    _buildTextField(
                                      controller: _phoneController,
                                      label: 'Phone Number',
                                      icon: Icons.phone,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: AppTheme.spacingM),
                                    _buildTextField(
                                      controller: _addressController,
                                      label: 'Address',
                                      icon: Icons.location_on,
                                      maxLines: 3,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: AppTheme.spacingXL),

                              // Update Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _updateProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: AppTheme.spacingM),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusM),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Update Profile',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
