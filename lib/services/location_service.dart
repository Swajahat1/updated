// import 'package:geolocator/geolocator.dart'; // Temporarily disabled
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  static Future<bool> _handleLocationPermission() async {
    // Fallback implementation without geolocator
    // Use permission_handler for basic permission check
    final status = await Permission.location.status;
    if (status.isDenied) {
      final result = await Permission.location.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  static Future<Map<String, dynamic>?> getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      return null;
    }

    // Fallback: Use IP-based location or return a default location
    // This is a simplified implementation
    try {
      // You could implement IP-based geolocation here
      // For now, return null to trigger IP-based location in the calling code
      return null;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getLocationDetails(
      double lat, double lng) async {
    try {
      // Reverse geocoding to get address details
      final response = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'latitude': lat,
          'longitude': lng,
          'address': data['display_name'] ?? 'Unknown location',
          'city': data['address']?['city'] ??
              data['address']?['town'] ??
              'Unknown city',
          'country': data['address']?['country'] ?? 'Unknown country',
          'source': 'GPS',
        };
      }
    } catch (e) {
      print('Error getting location details: $e');
    }

    return {
      'latitude': lat,
      'longitude': lng,
      'address':
          'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}',
      'city': 'Unknown',
      'country': 'Unknown',
      'source': 'GPS',
    };
  }

  static Future<List<dynamic>?> findNearbyTherapists(double lat, double lng,
      {double radius = 10}) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http:// 192.168.2.102:3000/api/therapists/nearby?lat=$lat&lng=$lng&radius=$radius'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['therapists'];
      }
    } catch (e) {
      print('Error finding nearby therapists: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateUserLocation(
      String userId, double lat, double lng) async {
    try {
      final response = await http.post(
        Uri.parse('http:// 192.168.2.102:3000/api/location/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'latitude': lat,
          'longitude': lng,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error updating user location: $e');
    }
    return null;
  }

  static double calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    // Simple distance calculation using Haversine formula
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = (lat2 - lat1) * (3.14159 / 180);
    double dLng = (lng2 - lng1) * (3.14159 / 180);

    double a = (dLat / 2) * (dLat / 2) +
        (lat1 * (3.14159 / 180)) *
            (lat2 * (3.14159 / 180)) *
            (dLng / 2) *
            (dLng / 2);

    double c = 2 * (a * a);
    return earthRadius * c;
  }

  static Future<Map<String, dynamic>?> getIPBasedLocation() async {
    try {
      final response = await http.get(
        Uri.parse('http:// 192.168.2.102:3000/api/location/ip-geo'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        data['source'] = 'IP';
        return data;
      }
    } catch (e) {
      print('Error getting IP-based location: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getBestAvailableLocation() async {
    // Try GPS first (currently returns null without geolocator)
    final position = await getCurrentPosition();
    if (position != null &&
        position['latitude'] != null &&
        position['longitude'] != null) {
      return await getLocationDetails(
          position['latitude'], position['longitude']);
    }

    // Fallback to IP-based location
    return await getIPBasedLocation();
  }
}
