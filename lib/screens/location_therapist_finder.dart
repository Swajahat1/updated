import 'package:flutter/material.dart';
import 'package:myapp/services/location_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/homepage/therapist_detail_screen.dart';

class LocationTherapistFinder extends StatefulWidget {
  final String userId;

  const LocationTherapistFinder({super.key, required this.userId});

  @override
  State<LocationTherapistFinder> createState() =>
      _LocationTherapistFinderState();
}

class _LocationTherapistFinderState extends State<LocationTherapistFinder> {
  bool _isLoadingLocation = false;
  bool _isLoadingTherapists = false;
  Map<String, dynamic>? _currentPosition;
  List<Map<String, dynamic>> _nearbyTherapists = [];
  String _locationStatus = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndFindTherapists();
  }

  Future<void> _getCurrentLocationAndFindTherapists() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Getting your location...';
    });

    try {
      // Get current position using geolocator
      final position = await LocationService.getCurrentPosition();

      if (position != null) {
        setState(() {
          _currentPosition = position;
          _locationStatus =
              'Location found! Searching for nearby therapists...';
          _isLoadingLocation = false;
          _isLoadingTherapists = true;
        });

        // Find nearby therapists
        await _findNearbyTherapists(
            position['latitude'], position['longitude']);
      } else {
        setState(() {
          _locationStatus = 'Location access denied. Showing all therapists...';
          _isLoadingLocation = false;
          _isLoadingTherapists = true;
        });

        // Fallback to all therapists
        await _loadAllTherapists();
      }
    } catch (e) {
      setState(() {
        _locationStatus = 'Error getting location: $e';
        _isLoadingLocation = false;
        _isLoadingTherapists = true;
      });

      // Fallback to all therapists
      await _loadAllTherapists();
    }
  }

  Future<void> _findNearbyTherapists(double latitude, double longitude) async {
    try {
      // Fetch all therapists
      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/therapists'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> allTherapists = jsonDecode(response.body);

        // Calculate distances and sort by proximity
        List<Map<String, dynamic>> therapistsWithDistance = [];

        for (var therapist in allTherapists) {
          // Use random coordinates for demo (in real app, therapists would have actual locations)
          double therapistLat =
              latitude + ((-1 + 2 * (therapist.hashCode % 100) / 100) * 0.1);
          double therapistLng = longitude +
              ((-1 + 2 * ((therapist.hashCode * 2) % 100) / 100) * 0.1);

          double distance = LocationService.calculateDistance(
              latitude, longitude, therapistLat, therapistLng);

          therapistsWithDistance.add({
            ...therapist,
            'distance': distance,
            'latitude': therapistLat,
            'longitude': therapistLng,
          });
        }

        // Sort by distance
        therapistsWithDistance
            .sort((a, b) => a['distance'].compareTo(b['distance']));

        setState(() {
          _nearbyTherapists = therapistsWithDistance;
          _isLoadingTherapists = false;
          _locationStatus =
              'Found ${therapistsWithDistance.length} therapists nearby';
        });
      }
    } catch (e) {
      setState(() {
        _locationStatus = 'Error loading therapists: $e';
        _isLoadingTherapists = false;
      });
    }
  }

  Future<void> _loadAllTherapists() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/therapists'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> therapists = jsonDecode(response.body);

        setState(() {
          _nearbyTherapists = therapists.cast<Map<String, dynamic>>();
          _isLoadingTherapists = false;
          _locationStatus = 'Showing all available therapists';
        });
      }
    } catch (e) {
      setState(() {
        _locationStatus = 'Error loading therapists: $e';
        _isLoadingTherapists = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Nearby Therapists'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _getCurrentLocationAndFindTherapists,
          ),
        ],
      ),
      body: Column(
        children: [
          // Location Status Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _currentPosition != null
                  ? Colors.green[50]
                  : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _currentPosition != null
                    ? Colors.green[200]!
                    : Colors.orange[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _currentPosition != null
                      ? Icons.location_on
                      : Icons.location_off,
                  color: _currentPosition != null
                      ? Colors.green[600]
                      : Colors.orange[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentPosition != null
                            ? 'Location Found'
                            : 'Location Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _currentPosition != null
                              ? Colors.green[700]
                              : Colors.orange[700],
                        ),
                      ),
                      Text(
                        _locationStatus,
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentPosition != null
                              ? Colors.green[600]
                              : Colors.orange[600],
                        ),
                      ),
                      if (_currentPosition != null)
                        Text(
                          'Lat: ${_currentPosition!['latitude'].toStringAsFixed(4)}, '
                          'Lng: ${_currentPosition!['longitude'].toStringAsFixed(4)}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[500],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isLoadingLocation || _isLoadingTherapists)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Therapists List
          Expanded(
            child: _isLoadingTherapists
                ? const Center(child: CircularProgressIndicator())
                : _nearbyTherapists.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No therapists found'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _nearbyTherapists.length,
                        itemBuilder: (context, index) {
                          final therapist = _nearbyTherapists[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(
                                  (therapist['username'] ??
                                          therapist['name'] ??
                                          'T')[0]
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                therapist['username'] ??
                                    therapist['name'] ??
                                    'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(therapist['email'] ?? ''),
                                  Text(
                                    therapist['specialization'] ??
                                        'General Therapy',
                                    style: TextStyle(color: Colors.blue[600]),
                                  ),
                                  if (therapist['distance'] != null)
                                    Row(
                                      children: [
                                        Icon(Icons.location_on,
                                            size: 16, color: Colors.green[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${therapist['distance'].toStringAsFixed(1)} km away',
                                          style: TextStyle(
                                            color: Colors.green[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () => _bookAppointment(therapist),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Book'),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _bookAppointment(Map<String, dynamic> therapist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Therapist: ${therapist['username'] ?? therapist['name']}'),
            Text('Specialization: ${therapist['specialization'] ?? 'General'}'),
            if (therapist['distance'] != null)
              Text('Distance: ${therapist['distance'].toStringAsFixed(1)} km'),
            const SizedBox(height: 16),
            const Text(
                'Would you like to book an appointment with this therapist?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to proper therapist detail screen for booking
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TherapistDetailScreen(
                    therapist: therapist,
                    userId: widget.userId,
                  ),
                ),
              );
            },
            child: const Text('Book Appointment'),
          ),
        ],
      ),
    );
  }
}
