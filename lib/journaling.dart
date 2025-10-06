import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:myapp/theme/app_theme.dart';

class JournalScreen extends StatefulWidget {
  final String userId; // Pass userId to the screen

  const JournalScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _JournalScreenState createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController _entryController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _journalEntriesFuture;
  final String _selectedMood = 'neutral'; // Default mood
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _journalEntriesFuture = _fetchJournalEntries(); // Fetch entries on init
  }

  // Fetch journal entries from the API
  Future<List<Map<String, dynamic>>> _fetchJournalEntries() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/journal/user/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((entry) => {
                  'id': entry['_id'],
                  'date': entry['entryDate'],
                  'entry': entry['content'],
                  'sentimentScore': entry['sentimentScore'],
                })
            .toList();
      } else {
        throw Exception('Failed to load journal entries: ${response.body}');
      }
    } catch (e) {
      print('Fetch Error: $e'); // Log error for debugging
      throw Exception('Error fetching entries: $e');
    }
  }

  // Create a new journal entry
  Future<void> _addJournalEntry(String content) async {
    if (content.isEmpty) return; // Prevent empty entries

    setState(() => _isLoading = true);

    try {
      final payload = {
        'userId': widget.userId,
        'date': DateTime.now().toIso8601String(),
        'sentimentScore': 0,
        'content': content,
      };
      print('Sending payload: $payload'); // Log payload for debugging

      final response = await http.post(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/journal/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      print(
          'Response: ${response.statusCode} ${response.body}'); // Log response

      if (response.statusCode == 201) {
        setState(() {
          _journalEntriesFuture = _fetchJournalEntries(); // Refresh entries
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal entry saved!')),
        );
      } else {
        throw Exception('Failed to save entry: ${response.body}');
      }
    } catch (e) {
      print('Save Error: $e'); // Log error for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving entry: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Delete a journal entry
  Future<void> _deleteJournalEntry(String entryId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/journal/$entryId'),
        headers: {'Content-Type': 'application/json'},
      );

      print(
          'Delete Response: ${response.statusCode} ${response.body}'); // Log response

      if (response.statusCode == 200) {
        setState(() {
          _journalEntriesFuture = _fetchJournalEntries(); // Refresh entries
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal entry deleted!')),
        );
      } else {
        throw Exception('Failed to delete entry: ${response.body}');
      }
    } catch (e) {
      print('Delete Error: $e'); // Log error for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting entry: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern App Bar
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppTheme.radiusXL),
                    bottomRight: Radius.circular(AppTheme.radiusXL),
                  ),
                  boxShadow: AppTheme.mediumShadow,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        "My Journal",
                        style: AppTheme.headingMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: IconButton(
                        icon:
                            const Icon(Icons.add_rounded, color: Colors.white),
                        onPressed: () => _showCreateEntryDialog(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              // Content Area
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _journalEntriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppTheme.spacingL),
                              decoration: BoxDecoration(
                                gradient: AppTheme.cardGradient,
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusL),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            Text(
                              'Loading journal entries...',
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(AppTheme.spacingL),
                          padding: const EdgeInsets.all(AppTheme.spacingL),
                          decoration: BoxDecoration(
                            gradient: AppTheme.cardGradient,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusL),
                            boxShadow: AppTheme.softShadow,
                            border: Border.all(
                              color: AppTheme.errorColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.all(AppTheme.spacingM),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusRound),
                                ),
                                child: Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                              const SizedBox(height: AppTheme.spacingM),
                              Text(
                                'Error: ${snapshot.error}',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.errorColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildNoEntriesView();
                    } else {
                      final journalEntries = snapshot.data!;
                      return _buildJournalEntriesView(journalEntries);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoEntriesView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingL),
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              ),
              child: Icon(
                Icons.book_rounded,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'No journal entries yet',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Start writing your thoughts and feelings to track your mental wellness journey.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: AppTheme.softShadow,
              ),
              child: ElevatedButton.icon(
                onPressed: _showCreateEntryDialog,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  'Add Your First Entry',
                  style: AppTheme.buttonText.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: AppTheme.spacingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalEntriesView(List<Map<String, dynamic>> journalEntries) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              boxShadow: AppTheme.softShadow,
            ),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _showCreateEntryDialog,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text(
                'Add New Entry',
                style: AppTheme.buttonText.copyWith(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingM,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Your Journal Entries (${journalEntries.length})',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: journalEntries.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppTheme.spacingM),
            itemBuilder: (context, index) {
              final entry = journalEntries[index];
              return Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  boxShadow: AppTheme.softShadow,
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _viewFullEntry(context, entry),
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.spacingM,
                                  vertical: AppTheme.spacingS,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusM),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: AppTheme.spacingS),
                                    Text(
                                      DateFormat.yMMMd().format(
                                          DateTime.parse(entry['date'])),
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withOpacity(0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusS),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.delete_rounded,
                                    color: AppTheme.errorColor,
                                    size: 20,
                                  ),
                                  onPressed: () =>
                                      _deleteJournalEntry(entry['id']),
                                  tooltip: 'Delete Entry',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacingM),
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.05),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              entry['entry'],
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingS),
                          Row(
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 16,
                                color: AppTheme.primaryColor.withOpacity(0.7),
                              ),
                              const SizedBox(width: AppTheme.spacingXS),
                              Text(
                                'Tap to read full entry',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.primaryColor.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateEntryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Journal Entry'),
          content: TextField(
            controller: _entryController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Write your thoughts, feelings, or experiences...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      final entry = _entryController.text;
                      if (entry.isNotEmpty) {
                        _addJournalEntry(entry);
                        _entryController.clear();
                        Navigator.of(context).pop();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please write something before saving.')),
                        );
                      }
                    },
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _viewFullEntry(BuildContext context, Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              'Journal Entry - ${DateFormat.yMMMd().format(DateTime.parse(entry['date']))}'),
          content: SingleChildScrollView(
            child: Text(
              entry['entry'],
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }
}
