import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/therapists'),
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

  void _filterTherapists() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTherapists = _therapists.where((therapist) {
        final username = therapist['username']?.toString().toLowerCase() ?? '';
        final email = therapist['email']?.toString().toLowerCase() ?? '';
        final specialization =
            therapist['specialization']?.toString().toLowerCase() ?? '';
        return username.contains(query) ||
            email.contains(query) ||
            specialization.contains(query);
      }).toList();
    });
  }

  Future<void> _approveTherapist(String therapistId, bool approved) async {
    try {
      final response = await http.put(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/therapists/$therapistId/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': 'admin-user-id',
          'approved': approved,
          'rejectionReason': approved ? null : 'Admin decision'
        }),
      );

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
      } else {
        throw Exception(
            'Failed to ${approved ? 'approve' : 'reject'} therapist');
      }
    } catch (e) {
      _showErrorDialog(
          'Failed to ${approved ? 'approve' : 'reject'} therapist: $e');
    }
  }

  void _showApprovalDialog(String therapistId, bool approve) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Therapist' : 'Reject Therapist'),
        content: Text(
          approve
              ? 'Are you sure you want to approve this therapist? They will be able to sign in and accept appointments.'
              : 'Are you sure you want to reject this therapist? They will not be able to sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveTherapist(therapistId, approve);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: approve ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? 'Approve' : 'Reject'),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText:
                    'Search therapists by name, email, or specialization...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Therapists List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTherapists.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology_outlined,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No therapists found',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF50C878),
                                    Color(0xFF32CD32)
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.psychology,
                                      color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Therapists (${_filteredTherapists.length})',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.refresh,
                                        color: Colors.white),
                                    onPressed: _fetchTherapists,
                                  ),
                                ],
                              ),
                            ),
                            // Therapists List
                            Expanded(
                              child: ListView.builder(
                                itemCount: _filteredTherapists.length,
                                itemBuilder: (context, index) {
                                  final therapist = _filteredTherapists[index];
                                  return _buildTherapistTile(therapist);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTherapistTile(Map<String, dynamic> therapist) {
    final username = therapist['username'] ?? therapist['name'] ?? 'N/A';
    final email = therapist['email'] ?? 'N/A';
    final specialization = therapist['specialization'] ?? 'General Therapy';
    final isApproved = therapist['isApproved'] ?? false;
    final isBlocked = therapist['isBlocked'] ?? false;
    final createdAt = therapist['createdAt'] != null
        ? DateTime.parse(therapist['createdAt']).toLocal()
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: isApproved ? Colors.green[100] : Colors.orange[100],
          child: Icon(
            Icons.psychology,
            color: isApproved ? Colors.green[600] : Colors.orange[600],
          ),
        ),
        title: Text(
          username,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    specialization,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isApproved ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isApproved ? 'APPROVED' : 'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color:
                          isApproved ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Joined: ${createdAt.day}/${createdAt.month}/${createdAt.year}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isApproved) ...[
              ElevatedButton(
                onPressed: () => _showApprovalDialog(therapist['_id'], true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Approve'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _showApprovalDialog(therapist['_id'], false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Reject'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => _showApprovalDialog(therapist['_id'], false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Revoke'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _editTherapist(Map<String, dynamic> therapist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Therapist'),
        content: Text(
            'Edit functionality for ${therapist['username'] ?? therapist['name']} would be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteTherapist(Map<String, dynamic> therapist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Therapist'),
        content: Text(
            'Are you sure you want to delete ${therapist['username'] ?? therapist['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Delete functionality would be implemented here'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
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
