import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/user_appointments_screen.dart';
import 'package:myapp/services/location_service.dart';
import 'package:myapp/components/custom_bottom_nav.dart';
import 'package:myapp/homepage/therapist_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? userDetails;
  List<dynamic>? therapists;
  List<dynamic>? filteredTherapists;
  bool isLoading = true;
  String? errorMessage;
  String? meetLink;
  bool isCreatingMeet = false;
  Map<String, dynamic>? userLocation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchTherapists();
    _fetchUserLocation();
    _searchController.addListener(_filterTherapists);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTherapists() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredTherapists = therapists;
      });
    } else {
      setState(() {
        filteredTherapists = therapists?.where((therapist) {
          final name = therapist['name']?.toString().toLowerCase() ?? '';
          final specialty =
              therapist['specialty']?.toString().toLowerCase() ?? '';
          final location =
              therapist['location']?.toString().toLowerCase() ?? '';
          return name.contains(query) ||
              specialty.contains(query) ||
              location.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _fetchUserDetails() async {
    final url =
        'https://mindease-backend-production.up.railway.app/api/users/${widget.userId}';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json"
        }, // Add content type header
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // Handle both direct user object and nested user object
        final userData = responseData is Map
            ? (responseData['user'] ?? responseData)
            : responseData;

        setState(() {
          userDetails = userData;
          isLoading = false;
          errorMessage = null; // Clear any previous errors
        });
      } else {
        final errorMsg = response.body.isNotEmpty
            ? jsonDecode(response.body)['message'] ??
                'Failed to load user details'
            : 'Failed to load user details';
        setState(() {
          errorMessage = errorMsg;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while connecting to the server';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchTherapists() async {
    const url =
        'https://mindease-backend-production.up.railway.app/api/therapists';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          therapists = jsonDecode(response.body);
          filteredTherapists = therapists; // Initialize filtered list
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load therapists';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred while fetching therapists: $e';
      });
    }
  }

  Future<void> _fetchUserLocation() async {
    try {
      // Try to get the best available location (GPS first, then IP)
      final location = await LocationService.getBestAvailableLocation();

      if (location != null) {
        setState(() {
          userLocation = location;
        });

        // Update user location in backend if GPS was used
        if (location['source'] == 'GPS') {
          await LocationService.updateUserLocation(
            widget.userId,
            location['latitude'],
            location['longitude'],
          );
        }
      } else {
        setState(() {
          userLocation = null;
        });
      }
    } catch (e) {
      setState(() {
        userLocation = null;
      });
    }
  }

  void _findNearbyTherapists() async {
    if (userLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Location not available. Please enable location services.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finding nearby therapists...')),
      );

      // Fetch therapists from API
      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/therapists'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> allTherapists = jsonDecode(response.body);

        // Filter therapists by location based on city/region
        List<dynamic> nearbyTherapists = allTherapists.where((therapist) {
          final therapistLocation =
              therapist['location']?.toString().toLowerCase() ?? '';
          final userCity =
              userLocation!['city']?.toString().toLowerCase() ?? '';
          final userRegion =
              userLocation!['region']?.toString().toLowerCase() ?? '';

          return therapistLocation.contains(userCity) ||
              therapistLocation.contains(userRegion) ||
              userCity.contains(therapistLocation) ||
              userRegion.contains(therapistLocation);
        }).toList();

        // If no nearby therapists found, show all therapists
        if (nearbyTherapists.isEmpty) {
          nearbyTherapists = allTherapists;
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AllTherapistsScreen(
                therapists: nearbyTherapists,
                userId: widget.userId,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load therapists. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToTherapistList() async {
    try {
      // Fetch therapists from API
      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/therapists'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> therapists = jsonDecode(response.body);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AllTherapistsScreen(
                therapists: therapists,
                userId: widget.userId,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load therapists. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationInfo() {
    if (userLocation != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Your Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('City: ${userLocation!['city'] ?? 'Unknown'}'),
              Text('Region: ${userLocation!['region'] ?? 'Unknown'}'),
              Text('Country: ${userLocation!['country'] ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text(
                'Source: ${userLocation!['source'] == 'GPS' ? 'GPS Location' : 'IP Location'}',
                style: TextStyle(
                  fontSize: 12,
                  color: userLocation!['source'] == 'GPS'
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (userLocation!['latitude'] != null &&
                  userLocation!['longitude'] != null)
                Text(
                  'Coordinates: ${userLocation!['latitude']?.toStringAsFixed(4)}, ${userLocation!['longitude']?.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              const SizedBox(height: 16),
              const Text(
                'We use this to find therapists near you.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Refresh location
                await _fetchUserLocation();
                // Show updated location
                _showLocationInfo();
              },
              child: const Text('Refresh GPS'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _findNearbyTherapists();
              },
              child: const Text('Find Nearby'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Not Available'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Unable to determine your location.'),
              SizedBox(height: 8),
              Text(
                'This might be because:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• You\'re testing on  192.168.2.102'),
              Text('• Network connectivity issues'),
              Text('• Location service is down'),
              SizedBox(height: 16),
              Text(
                'Check the console for detailed error messages.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _fetchUserLocation(); // Retry
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Retrying location fetch...')),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  // Build Welcome Section
  Widget _buildWelcomeSection() {
    final currentHour = DateTime.now().hour;
    String greeting = 'Good Morning';
    String emoji = '🌅';

    if (currentHour >= 12 && currentHour < 17) {
      greeting = 'Good Afternoon';
      emoji = '☀️';
    } else if (currentHour >= 17) {
      greeting = 'Good Evening';
      emoji = '🌙';
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$greeting,",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${userDetails?['username'] ?? 'Friend'}!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            "How are you feeling today? Remember, taking care of your mental health is just as important as your physical health. 💙",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // Build Quick Actions Section
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.video_call,
                title: "Start Session",
                subtitle: "Connect with therapist",
                color: AppTheme.accentColor,
                onTap: _navigateToTherapistList,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_today,
                title: "My Appointments",
                subtitle: "View & manage",
                color: AppTheme.successColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          UserAppointmentsScreen(userId: widget.userId),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Build Mood Check Section
  Widget _buildMoodCheckSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              const Expanded(
                child: Text(
                  "How are you feeling today?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Text(
            "Track your mood and get personalized insights",
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMoodButton("😊", "Great", Colors.green),
              _buildMoodButton("🙂", "Good", Colors.blue),
              _buildMoodButton("😐", "Okay", Colors.orange),
              _buildMoodButton("😔", "Low", Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  // Build Action Card Helper
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build Mood Button Helper
  Widget _buildMoodButton(String emoji, String label, Color color) {
    return GestureDetector(
      onTap: () {
        // Handle mood selection
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("You're feeling $label today! 💙"),
            backgroundColor: color,
            duration: const Duration(seconds: 2),
          ),
        );
        // Here you could save the mood to database
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Build Find Therapist Section
  Widget _buildFindTherapistSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withOpacity(0.8),
            AppTheme.primaryColor
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              const Expanded(
                child: Text(
                  "Find Your Perfect Therapist",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Text(
            "Connect with licensed professionals who understand your needs",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _navigateToTherapistList,
                  icon: const Icon(Icons.search),
                  label: const Text("Browse All"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _findNearbyTherapists,
                  icon: const Icon(Icons.location_on),
                  label: const Text("Find Nearby"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      side: const BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build Support Categories Section
  Widget _buildSupportCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "What brings you here today?",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        const Text(
          "Choose what you'd like support with",
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppTheme.spacingM,
          mainAxisSpacing: AppTheme.spacingM,
          childAspectRatio: 1.2,
          children: [
            _buildCategoryCard(
              icon: Icons.sentiment_very_dissatisfied,
              title: "Feeling Down",
              subtitle: "Depression support",
              color: Colors.blue,
              onTap: () {
                Navigator.pushNamed(context, '/mood_journal');
              },
            ),
            _buildCategoryCard(
              icon: Icons.psychology_alt,
              title: "Anxious Thoughts",
              subtitle: "Anxiety management",
              color: Colors.purple,
              onTap: () {
                Navigator.pushNamed(context, '/journaling');
              },
            ),
            _buildCategoryCard(
              icon: Icons.bedtime,
              title: "Sleep Issues",
              subtitle: "Better rest",
              color: Colors.indigo,
              onTap: () {
                // Navigate to sleep resources
              },
            ),
            _buildCategoryCard(
              icon: Icons.favorite,
              title: "Relationships",
              subtitle: "Connection help",
              color: Colors.pink,
              onTap: () {
                // Navigate to relationship resources
              },
            ),
          ],
        ),
      ],
    );
  }

  // Build Category Card Helper
  Widget _buildCategoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              ),
              child: Icon(
                icon,
                color: color,
                size: 32,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Build Featured Therapists Section
  Widget _buildFeaturedTherapistsSection(double cardWidth, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Featured Therapists",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: _navigateToTherapistList,
              child: const Text(
                "View All",
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        therapists == null || therapists!.isEmpty
            ? Container(
                padding: const EdgeInsets.all(AppTheme.spacingXL),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: AppTheme.textLight,
                      ),
                      SizedBox(height: AppTheme.spacingM),
                      Text(
                        "No therapists available right now",
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      Text(
                        "Check back later or contact support",
                        style: TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox(
                height: isSmallScreen ? 180 : 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: (filteredTherapists ?? therapists)!.length > 5
                      ? 5
                      : (filteredTherapists ?? therapists)!.length,
                  itemBuilder: (context, index) {
                    final therapist =
                        (filteredTherapists ?? therapists)![index];
                    return Padding(
                      padding: const EdgeInsets.only(right: AppTheme.spacingM),
                      child: _buildTherapistCard(therapist, isSmallScreen),
                    );
                  },
                ),
              ),
      ],
    );
  }

  // Build Resources Section
  Widget _buildResourcesSection() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: AppTheme.calmGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                child: const Icon(
                  Icons.auto_stories,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              const Expanded(
                child: Text(
                  "Mental Health Resources",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          const Text(
            "Helpful tools and information for your wellness journey",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Row(
            children: [
              Expanded(
                child: _buildResourceButton(
                  icon: Icons.quiz,
                  title: "Take Assessment",
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/anxiety_depression_test',
                      arguments: {'userId': widget.userId},
                    );
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _buildResourceButton(
                  icon: Icons.book,
                  title: "Mood Journal",
                  onTap: () {
                    Navigator.pushNamed(context, '/mood_journal');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build Therapist Card Helper
  Widget _buildTherapistCard(
      Map<String, dynamic> therapist, bool isSmallScreen) {
    return GestureDetector(
      onTap: () {
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
      child: Container(
        width: isSmallScreen ? 160 : 180,
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              ),
              child: const Icon(
                Icons.person,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              therapist['name'] ?? 'Unknown',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacingXS),
            Text(
              therapist['specialty'] ?? 'Therapist',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  "4.5",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build Resource Button Helper
  Widget _buildResourceButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Icon(
                Icons.psychology_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            const Text(
              "MindEase",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              // Show notifications
            },
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Profile',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style:
                        AppTheme.bodyLarge.copyWith(color: AppTheme.errorColor),
                  ),
                )
              : _buildHomeContent(context, screenWidth, isSmallScreen),
      bottomNavigationBar: CustomBottomNav(
        userId: widget.userId,
        currentIndex: 0, // Home is always index 0
        onTap: (index) {
          switch (index) {
            case 0:
              // Already on home - do nothing
              break;
            case 1:
              Navigator.pushNamed(
                context,
                '/analysis',
                arguments: {'userId': widget.userId},
              );
              break;
            case 2:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
      ),
    );
  }

  Widget _buildHomeContent(
      BuildContext context, double screenWidth, bool isSmallScreen) {
    final cardWidth = isSmallScreen ? screenWidth * 0.35 : 140.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Welcome Section
          _buildWelcomeSection(),
          const SizedBox(height: AppTheme.spacingL),

          // Quick Actions Section
          _buildQuickActionsSection(),
          const SizedBox(height: AppTheme.spacingL),

          // How are you feeling today?
          _buildMoodCheckSection(),
          const SizedBox(height: AppTheme.spacingL),

          // Find Your Therapist Section
          _buildFindTherapistSection(),
          const SizedBox(height: AppTheme.spacingL),

          // Support Categories Section
          _buildSupportCategoriesSection(),
          const SizedBox(height: AppTheme.spacingL),

          // Featured Therapists Section
          _buildFeaturedTherapistsSection(cardWidth, isSmallScreen),
          const SizedBox(height: AppTheme.spacingL),

          // Mental Health Resources Section
          _buildResourcesSection(),
          const SizedBox(height: AppTheme.spacingL),
        ],
      ),
    );
  }
}

class AllTherapistsScreen extends StatelessWidget {
  final List<dynamic> therapists;
  final String userId;

  const AllTherapistsScreen({
    super.key,
    required this.therapists,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
          ),
        ),
        title: Text(
          "All Therapists",
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: therapists.isEmpty
          ? const Center(
              child: Text(
                "No therapists available",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
              itemCount: therapists.length,
              itemBuilder: (context, index) {
                final therapist = therapists[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TherapistDetailScreen(
                          therapist: therapist,
                          userId: userId,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: isSmallScreen ? 25 : 30,
                            child: Image.asset(
                              'assets/images/user.png',
                              width: isSmallScreen ? 40 : 50,
                              height: isSmallScreen ? 40 : 50,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  therapist['name'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                                Text(
                                  therapist['specialty'] ?? 'Therapist',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  therapist['location'] ?? 'Unknown Location',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 10 : 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.purple),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class PhysicalAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> therapist;
  final String userId;

  const PhysicalAppointmentScreen({
    super.key,
    required this.therapist,
    required this.userId,
  });

  @override
  PhysicalAppointmentScreenState createState() =>
      PhysicalAppointmentScreenState();
}

class PhysicalAppointmentScreenState extends State<PhysicalAppointmentScreen> {
  DateTime? selectedDateTime;
  int? selectedDuration = 60;
  final TextEditingController notesController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> _selectDateTime() async {
    if (!mounted) return;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (selectedDateTime == null) {
      setState(() {
        errorMessage = 'Please select a date and time';
      });
      return;
    }
    if (selectedDateTime!.isBefore(DateTime.now())) {
      setState(() {
        errorMessage = 'Cannot book appointments in the past';
      });
      return;
    }
    if (widget.userId.isEmpty) {
      setState(() {
        errorMessage = 'User ID is missing';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/appointments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'therapistId': widget.therapist['_id'],
          'appointmentDate': selectedDateTime!.toUtc().toIso8601String(),
          'duration': selectedDuration,
          'notes': notesController.text,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Physical appointment booked with ${widget.therapist['name']}',
              ),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          errorMessage = errorData['message'] ?? 'Failed to book appointment';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Text(
          'Book Physical Appointment - ${widget.therapist['name']}',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Date and Time',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _selectDateTime(),
                      child: Text(
                        selectedDateTime == null
                            ? 'Pick Date & Time'
                            : DateFormat('yyyy-MM-dd HH:mm')
                                .format(selectedDateTime!),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 20),
                    Text(
                      'Duration (minutes)',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    DropdownButton<int>(
                      value: selectedDuration,
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 minutes')),
                        DropdownMenuItem(value: 60, child: Text('60 minutes')),
                        DropdownMenuItem(value: 90, child: Text('90 minutes')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedDuration = value;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 20),
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Any specific concerns or notes...',
                      ),
                      maxLines: 4,
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 20),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: isLoading ? null : _bookAppointment,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Book Appointment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}

class OnlineAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> therapist;
  final String userId;

  const OnlineAppointmentScreen({
    super.key,
    required this.therapist,
    required this.userId,
  });

  @override
  OnlineAppointmentScreenState createState() => OnlineAppointmentScreenState();
}

class OnlineAppointmentScreenState extends State<OnlineAppointmentScreen> {
  DateTime? selectedDateTime;
  int? selectedDuration = 60;
  final TextEditingController notesController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> _selectDateTime() async {
    if (!mounted) return;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null && mounted) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _bookAppointment() async {
    if (selectedDateTime == null) {
      setState(() {
        errorMessage = 'Please select a date and time';
      });
      return;
    }
    if (selectedDateTime!.isBefore(DateTime.now())) {
      setState(() {
        errorMessage = 'Cannot book appointments in the past';
      });
      return;
    }
    if (widget.userId.isEmpty) {
      setState(() {
        errorMessage = 'User ID is missing';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/appointments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.userId,
          'therapistId': widget.therapist['_id'],
          'appointmentDate': selectedDateTime!.toUtc().toIso8601String(),
          'duration': selectedDuration,
          'notes': notesController.text,
        }),
      );

      if (response.statusCode == 201) {
        final appointment = jsonDecode(response.body);
        if (mounted) {
          // Show appointment confirmation with Google Meet link
          _showOnlineAppointmentConfirmation(appointment);
        }
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          errorMessage = errorData['message'] ?? 'Failed to book appointment';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showOnlineAppointmentConfirmation(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Appointment Confirmed!'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your online appointment with ${widget.therapist['name']} has been successfully booked.',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meeting Details:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      if (appointment['meetingLink'] != null) ...[
                        Text('Google Meet Link:',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        SizedBox(height: 4),
                        SelectableText(
                          appointment['meetingLink'],
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                        SizedBox(height: 8),
                      ],
                      Text(
                          'Date: ${DateFormat('MMMM d, yyyy').format(DateTime.parse(appointment['appointmentDate']))}'),
                      Text(
                          'Time: ${DateFormat('h:mm a').format(DateTime.parse(appointment['appointmentDate']))}'),
                      Text('Duration: ${appointment['duration']} minutes'),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'The meeting link has been sent to your email. You can also find it in your appointments.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Text(
          'Book Online Appointment - ${widget.therapist['name']}',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 16 : 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Date and Time',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _selectDateTime(),
                      child: Text(
                        selectedDateTime == null
                            ? 'Pick Date & Time'
                            : DateFormat('yyyy-MM-dd HH:mm')
                                .format(selectedDateTime!),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 20),
                    Text(
                      'Duration (minutes)',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    DropdownButton<int>(
                      value: selectedDuration,
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 minutes')),
                        DropdownMenuItem(value: 60, child: Text('60 minutes')),
                        DropdownMenuItem(value: 90, child: Text('90 minutes')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedDuration = value;
                        });
                      },
                      isExpanded: true,
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 20),
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Any specific concerns or notes...',
                      ),
                      maxLines: 4,
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 20),
                    if (errorMessage != null)
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12 : 16,
                        ),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: isLoading ? null : _bookAppointment,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Book Appointment',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }
}

class StressScreen extends StatelessWidget {
  const StressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Text(
          'Stress',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Symptoms',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    Text(
                      '- Irritability or mood swings\n'
                      '- Headaches or muscle tension\n'
                      '- Fatigue or low energy\n'
                      '- Difficulty sleeping\n'
                      '- Racing thoughts or feeling overwhelmed\n'
                      '- Digestive issues (e.g., stomach aches)\n'
                      '- Changes in appetite\n'
                      '- Trouble concentrating',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 10 : 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Causes',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    Text(
                      '- Work or academic pressure\n'
                      '- Financial difficulties\n'
                      '- Relationship conflicts\n'
                      '- Major life changes (e.g., moving, job loss)\n'
                      '- Health problems\n'
                      '- Lack of work-life balance',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 10 : 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Effects',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    Text(
                      '- Weakened immune system\n'
                      '- Increased risk of anxiety or depression\n'
                      '- Burnout or chronic fatigue\n'
                      '- Strained personal relationships\n'
                      '- Poor decision-making\n'
                      '- Physical health issues (e.g., high blood pressure)',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InsomniaScreen extends StatelessWidget {
  const InsomniaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Text(
          'Insomnia',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Symptoms',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    Text(
                      '- Difficulty falling asleep\n'
                      '- Waking up frequently during the night\n'
                      '- Waking up too early\n'
                      '- Feeling unrefreshed after sleep\n'
                      '- Daytime fatigue or sleepiness\n'
                      '- Irritability or mood changes\n'
                      '- Trouble concentrating',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 10 : 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Causes',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    Text(
                      '- Stress or anxiety\n'
                      '- Poor sleep habits (e.g., irregular sleep schedule)\n'
                      '- Medical conditions (e.g., chronic pain, asthma)\n'
                      '- Medications or substance use (e.g., caffeine, alcohol)\n'
                      '- Mental health disorders (e.g., depression)\n'
                      '- Environmental factors (e.g., noise, light)',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 10 : 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Effects',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 5 : 10),
                    Text(
                      '- Decreased cognitive function (e.g., memory issues)\n'
                      '- Increased risk of accidents or injuries\n'
                      '- Mood disturbances (e.g., irritability, anxiety)\n'
                      '- Weakened immune system\n'
                      '- Higher risk of chronic diseases (e.g., diabetes)\n'
                      '- Reduced quality of life',
                      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalysisScreen extends StatelessWidget {
  final String userId;

  const AnalysisScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
          ),
        ),
        title: const Text(
          "Analysis & Insights",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Analysis Screen\nComing Soon!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        userId: userId,
        currentIndex: 1, // Analysis is index 1
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(userId: userId),
                ),
                (route) => false,
              );
              break;
            case 1:
              // Already on analysis - do nothing
              break;
            case 2:
              Navigator.pushNamed(context, '/settings');
              break;
          }
        },
      ),
    );
  }
}
