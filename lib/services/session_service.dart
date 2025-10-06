import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SessionService {
  static const String _userIdKey = 'userId';
  static const String _sessionTokenKey = 'sessionToken';
  static const String _userRoleKey = 'userRole';
  static const String _userEmailKey = 'userEmail';
  static const String _loginTimestampKey = 'loginTimestamp';
  static const String _isLoggedInKey = 'isLoggedIn';

  // Session expiry time (7 days in milliseconds)
  static const int _sessionExpiryDuration = 7 * 24 * 60 * 60 * 1000;

  static const String _baseUrl =
      'https://mindease-backend-production.up.railway.app/api';

  /// Save user session data after successful login
  static Future<void> saveSession({
    required String userId,
    required String sessionToken,
    required String userRole,
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await Future.wait([
      prefs.setString(_userIdKey, userId),
      prefs.setString(_sessionTokenKey, sessionToken),
      prefs.setString(_userRoleKey, userRole),
      prefs.setString(_userEmailKey, userEmail),
      prefs.setInt(_loginTimestampKey, timestamp),
      prefs.setBool(_isLoggedInKey, true),
    ]);
  }

  /// Check if user has a valid cached session
  static Future<bool> hasValidSession() async {
    final prefs = await SharedPreferences.getInstance();

    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    final loginTimestamp = prefs.getInt(_loginTimestampKey) ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (!isLoggedIn) return false;

    // Check if session has expired
    if (currentTime - loginTimestamp > _sessionExpiryDuration) {
      await clearSession();
      return false;
    }

    // Check if all required session data exists
    final userId = prefs.getString(_userIdKey);
    final sessionToken = prefs.getString(_sessionTokenKey);
    final userRole = prefs.getString(_userRoleKey);

    return userId != null && sessionToken != null && userRole != null;
  }

  /// Get cached session data
  static Future<Map<String, String>?> getSessionData() async {
    if (!await hasValidSession()) return null;

    final prefs = await SharedPreferences.getInstance();

    return {
      'userId': prefs.getString(_userIdKey) ?? '',
      'sessionToken': prefs.getString(_sessionTokenKey) ?? '',
      'userRole': prefs.getString(_userRoleKey) ?? '',
      'userEmail': prefs.getString(_userEmailKey) ?? '',
    };
  }

  /// Get user ID from cached session
  static Future<String?> getUserId() async {
    if (!await hasValidSession()) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  /// Get user role from cached session
  static Future<String?> getUserRole() async {
    if (!await hasValidSession()) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  /// Get session token from cached session
  static Future<String?> getSessionToken() async {
    if (!await hasValidSession()) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTokenKey);
  }

  /// Clear all session data (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      prefs.remove(_userIdKey),
      prefs.remove(_sessionTokenKey),
      prefs.remove(_userRoleKey),
      prefs.remove(_userEmailKey),
      prefs.remove(_loginTimestampKey),
      prefs.setBool(_isLoggedInKey, false),
    ]);
  }

  /// Validate session token with backend
  static Future<bool> validateSessionWithBackend() async {
    try {
      final sessionData = await getSessionData();
      if (sessionData == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/validate-session'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${sessionData['sessionToken']}',
        },
        body: jsonEncode({
          'userId': sessionData['userId'],
          'userRole': sessionData['userRole'],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valid'] == true;
      }

      return false;
    } catch (error) {
      print('Session validation error: $error');
      return false;
    }
  }

  /// Refresh session timestamp to extend session
  static Future<void> refreshSession() async {
    if (!await hasValidSession()) return;

    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_loginTimestampKey, timestamp);
  }

  /// Get session expiry date
  static Future<DateTime?> getSessionExpiryDate() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTimestamp = prefs.getInt(_loginTimestampKey);

    if (loginTimestamp == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(
        loginTimestamp + _sessionExpiryDuration);
  }

  /// Check if session will expire soon (within 24 hours)
  static Future<bool> isSessionExpiringSoon() async {
    final expiryDate = await getSessionExpiryDate();
    if (expiryDate == null) return false;

    final now = DateTime.now();
    final timeUntilExpiry = expiryDate.difference(now);

    return timeUntilExpiry.inHours <= 24;
  }

  /// Create HTTP headers with session token for authenticated requests
  static Future<Map<String, String>> getAuthHeaders() async {
    final sessionToken = await getSessionToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (sessionToken != null) {
      headers['Authorization'] = 'Bearer $sessionToken';
    }

    return headers;
  }

  /// Logout user and clear all session data
  static Future<void> logout() async {
    try {
      // Optionally notify backend about logout
      final sessionData = await getSessionData();
      if (sessionData != null) {
        try {
          await http.post(
            Uri.parse('$_baseUrl/auth/logout'),
            headers: await getAuthHeaders(),
            body: jsonEncode({
              'userId': sessionData['userId'],
            }),
          );
        } catch (e) {
          // Ignore backend logout errors, still clear local session
          print('Backend logout error (ignored): $e');
        }
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      // Always clear local session data
      await clearSession();
    }
  }
}
