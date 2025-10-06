import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/theme/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Fetching users from API...');
      final response = await http.get(
        Uri.parse('http:// 192.168.2.102:3000/api/users'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Users API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Users fetched successfully: ${data.length} users');
        setState(() {
          _users = data.cast<Map<String, dynamic>>();
          _filteredUsers = _users;
          _isLoading = false;
        });
      } else {
        print('❌ Users API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load users');
      }
    } catch (e) {
      print('❌ Exception in _fetchUsers: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to fetch users: $e');
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        final username = user['username']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        return username.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Future<void> _blockUser(String userId, bool isBlocked) async {
    try {
      debugPrint('🔧 Blocking user: $userId, current status: $isBlocked');

      final response = await http.put(
        Uri.parse('http:// 192.168.2.102:3000/api/users/$userId/block'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'isBlocked': !isBlocked}),
      );

      debugPrint('📊 Block response: ${response.statusCode}');
      debugPrint('📊 Block response body: ${response.body}');

      if (response.statusCode == 200) {
        _fetchUsers(); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isBlocked
                  ? 'User unblocked successfully'
                  : 'User blocked successfully'),
              backgroundColor: isBlocked ? Colors.green : Colors.red,
            ),
          );
        }
        debugPrint('✅ User block status updated successfully');
      } else {
        throw Exception('Failed to update user status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Block user error: $e');
      _showErrorDialog('Failed to update user: $e');
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', user['_id'] ?? 'N/A'),
              _buildDetailRow('Username', user['username'] ?? 'N/A'),
              _buildDetailRow('Email', user['email'] ?? 'N/A'),
              _buildDetailRow(
                  'Status', user['isBlocked'] == true ? 'Blocked' : 'Active'),
              _buildDetailRow('Created', user['createdAt'] ?? 'N/A'),
              _buildDetailRow('Mood Entries',
                  user['moodEntries']?.length.toString() ?? '0'),
              _buildDetailRow('Recommendations',
                  user['recommendations']?.length.toString() ?? '0'),
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
              _blockUser(user['_id'], user['isBlocked'] == true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  user['isBlocked'] == true ? Colors.green : Colors.red,
            ),
            child: Text(user['isBlocked'] == true ? 'Unblock' : 'Block'),
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
            width: 100,
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
                    hintText: 'Search users by username or email...',
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
                      'Total Users: ${_filteredUsers.length}',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _fetchUsers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          final isBlocked = user['isBlocked'] == true;

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
                                  isBlocked ? Icons.block : Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                user['username'] ?? 'Unknown User',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isBlocked ? Colors.red : Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['email'] ?? 'No email'),
                                  Text(
                                    'Status: ${isBlocked ? 'Blocked' : 'Active'}',
                                    style: TextStyle(
                                      color:
                                          isBlocked ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info),
                                    onPressed: () => _showUserDetails(user),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isBlocked
                                          ? Icons.check_circle
                                          : Icons.block,
                                      color:
                                          isBlocked ? Colors.green : Colors.red,
                                    ),
                                    onPressed: () =>
                                        _blockUser(user['_id'], isBlocked),
                                  ),
                                ],
                              ),
                              onTap: () => _showUserDetails(user),
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
