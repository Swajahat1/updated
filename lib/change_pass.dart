import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:myapp/home_page.dart';
import 'package:myapp/therapist_dashboard.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/services/session_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String userId;
  final String userType; // 'User' or 'Therapist'

  const ChangePasswordScreen({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isOldPasswordVisible = false;
  bool isNewPasswordVisible = false;

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  Future<void> changePassword(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final oldPassword = oldPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final userId = widget.userId;
    final userType = widget.userType;

    try {
      final endpoint = userType == 'User'
          ? "https://mindease-backend-production.up.railway.app/api/users/changePassword"
          : "https://mindease-backend-production.up.railway.app/api/therapists/changePassword";

      // Get authentication headers with session token
      final headers = await SessionService.getAuthHeaders();

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode({
          "id": userId,
          "oldPassword": oldPassword,
          "newPassword": newPassword,
        }),
      );

      Navigator.pop(context); // Close loading dialog

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
        // Navigate to appropriate dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => userType == 'User'
                ? HomeScreen(userId: userId)
                : TherapistDashboard(therapistId: userId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
      }
    } catch (error) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $error")),
      );
    }
  }

  String? validateOldPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Old password is required";
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "New password is required";
    }
    if (value.length < 6) {
      return "New password must be at least 6 characters";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE29F), Color(0xFFFFC0CB)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(),
                const SizedBox(height: 30),
                _inputFields(),
                const SizedBox(height: 20),
                _changePasswordButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: const [
        Text(
          "Change Password",
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          "Enter your old and new passwords",
          style: TextStyle(fontSize: 16, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _inputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: oldPasswordController,
          obscureText: !isOldPasswordVisible,
          decoration: InputDecoration(
            hintText: "Old Password",
            prefixIcon: const Icon(Icons.lock, color: Colors.purple),
            suffixIcon: IconButton(
              icon: Icon(
                isOldPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.purple,
              ),
              onPressed: () {
                setState(() {
                  isOldPasswordVisible = !isOldPasswordVisible;
                });
              },
            ),
          ),
          validator: validateOldPassword,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: newPasswordController,
          obscureText: !isNewPasswordVisible,
          decoration: InputDecoration(
            hintText: "New Password",
            prefixIcon: const Icon(Icons.lock, color: Colors.purple),
            suffixIcon: IconButton(
              icon: Icon(
                isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.purple,
              ),
              onPressed: () {
                setState(() {
                  isNewPasswordVisible = !isNewPasswordVisible;
                });
              },
            ),
          ),
          validator: validateNewPassword,
        ),
      ],
    );
  }

  Widget _changePasswordButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        await changePassword(context);
      },
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppTheme.primaryColor,
      ),
      child: const Text(
        "Change Password",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
