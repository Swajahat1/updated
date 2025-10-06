import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/services/location_service.dart';

import 'package:myapp/login_page.dart'; // Ensure this import is correct
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/components/modern_input.dart';
import 'package:myapp/components/modern_button.dart';

class CreateTherapistPage extends StatefulWidget {
  const CreateTherapistPage({super.key});

  @override
  _CreateTherapistPageState createState() => _CreateTherapistPageState();
}

class _CreateTherapistPageState extends State<CreateTherapistPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _bioController = TextEditingController();

  bool isPasswordVisible = false;
  bool _isLoading = false;
  Map<String, dynamic>? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _specialtyController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final location = await LocationService.getBestAvailableLocation();
      if (location != null) {
        setState(() {
          _currentLocation = location;
          _locationController.text = location['address'] ?? 'Current Location';
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _createTherapist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/therapists'), // Fixed: http instead of https
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'specialty': _specialtyController.text.trim(),
          'location': _locationController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
          'phone': _phoneController.text.trim().isNotEmpty
              ? _phoneController.text.trim()
              : '+1-555-0000',
          'experience': int.tryParse(_experienceController.text.trim()) ?? 1,
          'coordinates': {
            'type': 'Point',
            'coordinates': _currentLocation != null
                ? [
                    _currentLocation!['longitude'] ?? 0,
                    _currentLocation!['latitude'] ?? 0
                  ]
                : [0, 0]
          },
          'hourlyRate':
              double.tryParse(_hourlyRateController.text.trim()) ?? 100,
          'bio': _bioController.text.trim().isNotEmpty
              ? _bioController.text.trim()
              : 'Professional therapist dedicated to helping clients achieve mental wellness.',
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          // Show success dialog with approval message
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    SizedBox(width: 10),
                    Text('Registration Successful!'),
                  ],
                ),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your therapist account has been created successfully!',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 15),
                    Text(
                      '⏳ Pending Admin Approval',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your account is currently pending admin approval. You will be able to login once an administrator approves your account.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 15),
                    Text(
                      '📧 You will receive a notification once your account is approved.',
                      style: TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Go back to previous screen
                    },
                    child: const Text('OK', style: TextStyle(fontSize: 16)),
                  ),
                ],
              );
            },
          );
        }
        // Clear the form
        _nameController.clear();
        _specialtyController.clear();
        _locationController.clear();
        _emailController.clear();
        _passwordController.clear();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create therapist: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.backgroundGradient,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.spacingXL),
                    _header(),
                    const SizedBox(height: AppTheme.spacingXL),
                    _inputFields(),
                    const SizedBox(height: AppTheme.spacingL),
                    _createTherapistButton(),
                    const SizedBox(height: AppTheme.spacingXL),
                    _alreadyHaveAccount(),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(), // Loading indicator
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        // App Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
            boxShadow: AppTheme.softShadow,
          ),
          child: const Icon(
            Icons.medical_services,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          "Join as Therapist",
          style: AppTheme.headingLarge.copyWith(
            fontSize: 28,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          "Create your professional account to help patients",
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _inputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModernInput(
          label: "Full Name",
          hint: "Enter your full name",
          controller: _nameController,
          prefixIcon: Icons.person_outline,
          validator: (value) =>
              value == null || value.isEmpty ? "Please enter a name" : null,
        ),
        const SizedBox(height: AppTheme.spacingM),
        ModernInput(
          label: "Specialty",
          hint: "Enter your specialty",
          controller: _specialtyController,
          prefixIcon: Icons.medical_services_outlined,
          validator: (value) => value == null || value.isEmpty
              ? "Please enter a specialty"
              : null,
        ),
        const SizedBox(height: AppTheme.spacingM),
        ModernInput(
          label: "Location",
          hint: "Enter your location",
          controller: _locationController,
          prefixIcon: Icons.location_on_outlined,
          validator: (value) =>
              value == null || value.isEmpty ? "Please enter a location" : null,
        ),
        const SizedBox(height: AppTheme.spacingM),
        ModernInput(
          label: "Email Address",
          hint: "Enter your email",
          controller: _emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
            return value == null || !emailRegex.hasMatch(value)
                ? "Enter a valid email address"
                : null;
          },
        ),
        const SizedBox(height: AppTheme.spacingM),
        ModernInput(
          label: "Password",
          hint: "Enter your password",
          controller: _passwordController,
          prefixIcon: Icons.lock_outline,
          suffixIcon:
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          onSuffixIconPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
          obscureText: !isPasswordVisible,
          validator: (value) => value == null || value.length < 6
              ? "Password must be at least 6 characters long"
              : null,
        ),
        const SizedBox(height: AppTheme.spacingM),
        ModernInput(
          label: "Phone Number",
          hint: "Enter your phone number",
          controller: _phoneController,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          validator: (value) => value == null || value.isEmpty
              ? "Please enter a phone number"
              : null,
        ),
        const SizedBox(height: AppTheme.spacingM),
        ModernInput(
          label: "Years of Experience",
          hint: "Enter years of experience",
          controller: _experienceController,
          prefixIcon: Icons.work_outline,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter years of experience";
            }
            final experience = int.tryParse(value);
            if (experience == null || experience < 0) {
              return "Please enter a valid number";
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingM),
        ModernInput(
          label: "Hourly Rate (\$)",
          hint: "Enter your hourly rate",
          controller: _hourlyRateController,
          prefixIcon: Icons.attach_money_outlined,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Please enter your hourly rate";
            }
            final rate = double.tryParse(value);
            if (rate == null || rate <= 0) {
              return "Please enter a valid rate";
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingM),
        ModernInput(
          label: "Bio",
          hint: "Tell us about yourself and your expertise",
          controller: _bioController,
          prefixIcon: Icons.description_outlined,
          maxLines: 3,
          validator: (value) => value == null || value.isEmpty
              ? "Please enter a brief bio"
              : null,
        ),
      ],
    );
  }

  Widget _createTherapistButton() {
    return PrimaryButton(
      text: "Create Therapist Account",
      onPressed: _isLoading ? null : _createTherapist,
      icon: Icons.medical_services,
      isLoading: _isLoading,
    );
  }

  Widget _alreadyHaveAccount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: Text(
            "Login",
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
