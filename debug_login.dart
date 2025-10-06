import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await testLogin();
}

Future<void> testLogin() async {
  print("🔍 Testing login functionality...");

  // Test data - replace with actual user credentials
  final testEmail = "test@example.com";
  final testPassword = "password123";

  print("📧 Testing with email: $testEmail");

  try {
    // Test user login
    print("\n1️⃣ Testing user login...");
    final userResponse = await http.post(
      Uri.parse(
          "https://mindease-backend-production.up.railway.app/api/users/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": testEmail,
        "password": testPassword,
      }),
    );

    print("User login status: ${userResponse.statusCode}");
    print("User login response: ${userResponse.body}");

    if (userResponse.statusCode == 200) {
      final userData = jsonDecode(userResponse.body);
      print("✅ User login successful!");
      print("User ID: ${userData['user']?['_id']}");
    } else {
      print("❌ User login failed");
    }

    // Test therapist login
    print("\n2️⃣ Testing therapist login...");
    final therapistResponse = await http.post(
      Uri.parse(
          "https://mindease-backend-production.up.railway.app/api/therapists/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": testEmail,
        "password": testPassword,
        "role": "therapist",
      }),
    );

    print("Therapist login status: ${therapistResponse.statusCode}");
    print("Therapist login response: ${therapistResponse.body}");

    if (therapistResponse.statusCode == 200) {
      final therapistData = jsonDecode(therapistResponse.body);
      print("✅ Therapist login successful!");
      print("Therapist ID: ${therapistData['user']?['_id']}");
    } else {
      print("❌ Therapist login failed");
    }
  } catch (e) {
    print("🚨 Network error: $e");
    print(
        "This suggests the backend server might not be running or accessible.");
  }

  print("\n🔧 Debugging suggestions:");
  print(
      "1. Make sure the backend server is running on https://mindease-backend-production.up.railway.app");
  print("2. Check if you have valid user credentials in the database");
  print("3. Verify network connectivity between the app and server");
  print("4. Check server logs for any errors");
}
