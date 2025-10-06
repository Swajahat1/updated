import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/forget-password.dart';
import 'package:myapp/new_home_page.dart';
import 'package:myapp/signup_page.dart';
import 'package:myapp/therapist_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/components/modern_input.dart';
import 'package:myapp/components/modern_button.dart';
import 'package:myapp/services/session_service.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/ThemeProvider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      // Try to login as user first
      bool loginSuccessful =
          await _attemptLogin(context, email, password, "user", "users");

      if (!loginSuccessful) {
        // If user login fails, try therapist login
        loginSuccessful = await _attemptLogin(
            context, email, password, "therapist", "therapists");

        if (!loginSuccessful) {
          // Both failed, show error
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Invalid email or password")),
            );
          }
        }
      }
    } catch (error) {
      print("Login error: $error");
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An error occurred: $error")),
        );
      }
    }
  }

  Future<bool> _attemptLogin(BuildContext context, String email,
      String password, String role, String userType) async {
    try {
      print(
          "Attempting login as $role to: https://mindease-backend-production.up.railway.app/api/$userType/login");

      final response = await http.post(
        Uri.parse(
            "https://mindease-backend-production.up.railway.app/api/$userType/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "role": role,
        }),
      );

      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Decoded response data: $responseData");

        // Extract userId with null safety
        String? userId;

        // Try different possible response formats
        if (responseData is Map) {
          if (responseData.containsKey('user') && responseData['user'] is Map) {
            userId = responseData['user']['_id']?.toString();
          }
          if (userId == null && responseData.containsKey('userId')) {
            userId = responseData['userId']?.toString();
          }
          if (userId == null && responseData.containsKey('_id')) {
            userId = responseData['_id']?.toString();
          }
        }

        if (userId == null) {
          print("User ID not found in response: $responseData");
          return false;
        }

        print("Extracted userId: $userId");

        // Extract session token and user info
        final sessionToken = responseData['sessionToken']?.toString() ?? '';
        final userEmail = responseData['user']?['email']?.toString() ?? email;
        final userRole = responseData['user']?['role']?.toString() ?? role;

        // Save session data using SessionService
        if (sessionToken.isNotEmpty) {
          await SessionService.saveSession(
            userId: userId,
            sessionToken: sessionToken,
            userRole: userRole,
            userEmail: userEmail,
          );
          print("Session saved with token: ${sessionToken.substring(0, 8)}...");
        } else {
          // Fallback to old method if no session token
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', userId);
          print("Fallback: Saved userId to SharedPreferences");
        }

        // Navigate to the appropriate screen
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => userType == 'users'
                  ? NewHomeScreen(userId: userId!)
                  : TherapistDashboard(therapistId: userId!),
            ),
          );
        }
        return true;
      } else {
        // Login failed for this role, return false to try the other role
        return false;
      }
    } catch (error) {
      print("Login attempt error for $role: $error");
      return false;
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email is required";
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return "Enter a valid email";
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: themeProvider.getBackgroundGradient(),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.spacingXL),
                      _header(),
                      const SizedBox(height: AppTheme.spacingXXL),
                      _inputField(),
                      const SizedBox(height: AppTheme.spacingL),
                      _forgotPasswordButton(),
                      const SizedBox(height: AppTheme.spacingM),
                      _loginButton(context),
                      const SizedBox(height: AppTheme.spacingXL),
                      _signup(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          decoration: BoxDecoration(
            gradient: AppTheme.heroGradient,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppTheme.secondaryColor.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: const Icon(
            Icons.spa_outlined,
            size: 64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXL),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppTheme.primaryGradient.createShader(bounds),
          child: const Text(
            "Welcome Back!",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Text(
          "Continue your mental wellness journey",
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _inputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ModernInput(
          label: "Email Address",
          hint: "Enter your email",
          controller: emailController,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: validateEmail,
        ),
        const SizedBox(height: AppTheme.spacingM),
        ModernInput(
          label: "Password",
          hint: "Enter your password",
          controller: passwordController,
          prefixIcon: Icons.lock_outline,
          suffixIcon:
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          onSuffixIconPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
          obscureText: !isPasswordVisible,
          validator: validatePassword,
        ),
      ],
    );
  }

  Widget _forgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
          );
        },
        child: const Text(
          "Forgot Password?",
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _loginButton(BuildContext context) {
    return PrimaryButton(
      text: "Sign In",
      onPressed: () async {
        await login(context);
      },
      icon: Icons.login,
    );
  }

  Widget _signup() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Don't have an account? ",
          style: AppTheme.bodyMedium,
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignupPage()),
            );
          },
          child: const Text(
            "Sign Up",
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
