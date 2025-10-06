import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'theme/app_theme.dart';

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
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/users'),
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
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/users/$userId/block'),
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
      debugPrint('❌ Exception in _blockUser: $e');
      _showErrorDialog('Failed to update user status: $e');
    }
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
                hintText: 'Search users by name or email...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No users found',
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
                                    Color(0xFF667eea),
                                    Color(0xFF764ba2)
                                  ],
                                ),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.people, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Users (${_filteredUsers.length})',
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
                                    onPressed: _fetchUsers,
                                  ),
                                ],
                              ),
                            ),
                            // Users List
                            Expanded(
                              child: ListView.builder(
                                itemCount: _filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = _filteredUsers[index];
                                  return _buildUserTile(user);
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

  Widget _buildUserTile(Map<String, dynamic> user) {
    final isBlocked = user['isBlocked'] ?? false;
    final username = user['username'] ?? 'N/A';
    final email = user['email'] ?? 'N/A';
    final role = user['role'] ?? 'user';
    final createdAt = user['createdAt'] != null
        ? DateTime.parse(user['createdAt']).toLocal()
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBlocked
              ? Colors.red.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
        ),
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
          backgroundColor: isBlocked ? Colors.red[100] : Colors.blue[100],
          child: Icon(
            Icons.person,
            color: isBlocked ? Colors.red[600] : Colors.blue[600],
          ),
        ),
        title: Text(
          username,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isBlocked ? Colors.red[700] : Colors.black,
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
                    role.toUpperCase(),
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
                    color: isBlocked ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isBlocked ? 'BLOCKED' : 'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isBlocked ? Colors.red[700] : Colors.green[700],
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
        trailing: ElevatedButton(
          onPressed: () => _showBlockConfirmation(user['_id'], isBlocked),
          style: ElevatedButton.styleFrom(
            backgroundColor: isBlocked ? Colors.green : Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(isBlocked ? 'Unblock' : 'Block'),
        ),
      ),
    );
  }

  void _showBlockConfirmation(String userId, bool isCurrentlyBlocked) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCurrentlyBlocked ? 'Unblock User' : 'Block User'),
        content: Text(
          isCurrentlyBlocked
              ? 'Are you sure you want to unblock this user?'
              : 'Are you sure you want to block this user?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _blockUser(userId, isCurrentlyBlocked);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyBlocked ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(isCurrentlyBlocked ? 'Unblock' : 'Block'),
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
