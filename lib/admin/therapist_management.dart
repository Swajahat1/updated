import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/theme/app_theme.dart';

class TherapistManagementScreen extends StatefulWidget {
  const TherapistManagementScreen({super.key});

  @override
  _TherapistManagementScreenState createState() =>
      _TherapistManagementScreenState();
}

class _TherapistManagementScreenState extends State<TherapistManagementScreen> {
  List<Map<String, dynamic>> _therapists = [];
  List<Map<String, dynamic>> _filteredTherapists = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTherapists();
    _searchController.addListener(_filterTherapists);
  }

  Future<void> _fetchTherapists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Fetching therapists from API...');
      final response = await http.get(
        Uri.parse('http:// 192.168.2.102:3000/api/therapists'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Therapists API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Therapists fetched successfully: ${data.length} therapists');
        setState(() {
          _therapists = data.cast<Map<String, dynamic>>();
          _filteredTherapists = _therapists;
          _isLoading = false;
        });
      } else {
        print(
            '❌ Therapists API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load therapists');
      }
    } catch (e) {
      print('❌ Exception in _fetchTherapists: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to fetch therapists: $e');
    }
  }

  Future<void> _approveTherapist(String therapistId, bool approved) async {
    try {
      debugPrint(
          '🔧 ${approved ? 'Approving' : 'Rejecting'} therapist: $therapistId');

      final response = await http.put(
        Uri.parse(
            'http:// 192.168.2.102:3000/api/therapists/$therapistId/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': 'admin-user-id', // You can get this from user session
          'approved': approved,
          'rejectionReason': approved ? null : 'Admin decision'
        }),
      );

      debugPrint('📊 Approval response: ${response.statusCode}');
      debugPrint('📊 Approval response body: ${response.body}');

      if (response.statusCode == 200) {
        _fetchTherapists(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(approved
                  ? 'Therapist approved successfully'
                  : 'Therapist rejected successfully'),
              backgroundColor: approved ? Colors.green : Colors.orange,
            ),
          );
        }
        debugPrint(
            '✅ Therapist ${approved ? 'approved' : 'rejected'} successfully');
      } else {
        throw Exception(
            'Failed to ${approved ? 'approve' : 'reject'} therapist: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Approval error: $e');
      _showErrorDialog(
          'Failed to ${approved ? 'approve' : 'reject'} therapist: $e');
    }
  }

  void _filterTherapists() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTherapists = _therapists.where((therapist) {
        final name = therapist['name']?.toString().toLowerCase() ?? '';
        final email = therapist['email']?.toString().toLowerCase() ?? '';
        final specialization =
            therapist['specialization']?.toString().toLowerCase() ?? '';
        return name.contains(query) ||
            email.contains(query) ||
            specialization.contains(query);
      }).toList();
    });
  }

  Future<void> _blockTherapist(String therapistId, bool isBlocked) async {
    try {
      final response = await http.put(
        Uri.parse(
            'http:// 192.168.2.102:3000/api/therapists/$therapistId/block'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isBlocked': !isBlocked}),
      );

      if (response.statusCode == 200) {
        _fetchTherapists(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isBlocked
                ? 'Therapist unblocked successfully'
                : 'Therapist blocked successfully'),
            backgroundColor: isBlocked ? Colors.green : Colors.red,
          ),
        );
      } else {
        throw Exception('Failed to update therapist status');
      }
    } catch (e) {
      _showErrorDialog('Failed to update therapist: $e');
    }
  }

  void _showTherapistDetails(Map<String, dynamic> therapist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Therapist Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', therapist['_id'] ?? 'N/A'),
              _buildDetailRow('Name', therapist['name'] ?? 'N/A'),
              _buildDetailRow('Email', therapist['email'] ?? 'N/A'),
              _buildDetailRow('Phone', therapist['phone'] ?? 'N/A'),
              _buildDetailRow(
                  'Specialization', therapist['specialization'] ?? 'N/A'),
              _buildDetailRow(
                  'Experience', '${therapist['experience'] ?? 'N/A'} years'),
              _buildDetailRow(
                  'License Number', therapist['licenseNumber'] ?? 'N/A'),
              _buildDetailRow('Bio', therapist['bio'] ?? 'N/A'),
              _buildDetailRow('Status',
                  therapist['isBlocked'] == true ? 'Blocked' : 'Active'),
              _buildDetailRow(
                  'Verified', therapist['isVerified'] == true ? 'Yes' : 'No'),
              _buildDetailRow('Created', therapist['createdAt'] ?? 'N/A'),
              if (therapist['location'] != null &&
                  therapist['location']['coordinates'] != null)
                _buildDetailRow('Location',
                    'Lat: ${therapist['location']['coordinates'][1]}, Lng: ${therapist['location']['coordinates'][0]}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _blockTherapist(therapist['_id'], therapist['isBlocked'] == true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  therapist['isBlocked'] == true ? Colors.green : Colors.red,
            ),
            child: Text(therapist['isBlocked'] == true ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search therapists by name, email, or specialization...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Therapists: ${_filteredTherapists.length}',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _fetchTherapists,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Therapists List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTherapists.isEmpty
                    ? const Center(
                        child: Text(
                          'No therapists found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredTherapists.length,
                        itemBuilder: (context, index) {
                          final therapist = _filteredTherapists[index];
                          final isBlocked = therapist['isBlocked'] == true;
                          final isVerified = therapist['isVerified'] == true;
                          final isApproved = therapist['isApproved'] == true;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isBlocked
                                    ? Colors.red
                                    : AppTheme.primaryColor,
                                child: Icon(
                                  isBlocked ? Icons.block : Icons.psychology,
                                  color: Colors.white,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      therapist['name'] ?? 'Unknown Therapist',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isBlocked
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (isVerified)
                                    const Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(therapist['email'] ?? 'No email'),
                                  Text(therapist['specialty'] ??
                                      therapist['specialization'] ??
                                      'No specialization'),
                                  Text(
                                    'Status: ${isBlocked ? 'Blocked' : 'Active'}',
                                    style: TextStyle(
                                      color:
                                          isBlocked ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Approval: ${isApproved ? '✅ Approved' : '⏳ Pending'}',
                                    style: TextStyle(
                                      color: isApproved
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Approval buttons (only show if not approved)
                                  if (!isApproved) ...[
                                    IconButton(
                                      icon: const Icon(Icons.check,
                                          color: Colors.green),
                                      tooltip: 'Approve Therapist',
                                      onPressed: () => _approveTherapist(
                                          therapist['_id'], true),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      tooltip: 'Reject Therapist',
                                      onPressed: () => _approveTherapist(
                                          therapist['_id'], false),
                                    ),
                                  ],
                                  IconButton(
                                    icon: const Icon(Icons.info),
                                    onPressed: () =>
                                        _showTherapistDetails(therapist),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isBlocked
                                          ? Icons.check_circle
                                          : Icons.block,
                                      color:
                                          isBlocked ? Colors.green : Colors.red,
                                    ),
                                    onPressed: () => _blockTherapist(
                                        therapist['_id'], isBlocked),
                                  ),
                                ],
                              ),
                              onTap: () => _showTherapistDetails(therapist),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
