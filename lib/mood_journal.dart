import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:myapp/providers/user_provider.dart';
import 'package:myapp/theme/app_theme.dart';
import 'package:myapp/components/modern_bottom_nav.dart';
import 'package:intl/intl.dart';

class MoodJournalScreen extends StatefulWidget {
  final String userId;

  const MoodJournalScreen({super.key, required this.userId});

  @override
  State<MoodJournalScreen> createState() => _MoodJournalScreenState();
}

class _MoodJournalScreenState extends State<MoodJournalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _journalController = TextEditingController();

  bool _isLoading = false;
  List<MoodJournalEntry> moodJournalHistory = [];
  String _selectedMood = 'neutral';

  final List<Map<String, dynamic>> _moods = [
    {'name': 'happy', 'emoji': '😊', 'color': Colors.green},
    {'name': 'sad', 'emoji': '😢', 'color': Colors.blue},
    {'name': 'anxious', 'emoji': '😰', 'color': Colors.red},
    {'name': 'calm', 'emoji': '😌', 'color': Colors.teal},
    {'name': 'excited', 'emoji': '🤩', 'color': Colors.orange},
    {'name': 'stressed', 'emoji': '😤', 'color': Colors.purple},
    {'name': 'neutral', 'emoji': '😐', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchMoodJournalHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _fetchMoodJournalHistory() async {
    final userId = widget.userId;

    if (userId.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch mood entries
      final moodResponse = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/mood/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      // Fetch journal entries
      final journalResponse = await http.get(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/journal/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (moodResponse.statusCode == 200 && journalResponse.statusCode == 200) {
        final moodData = jsonDecode(moodResponse.body) as List;
        final journalData = jsonDecode(journalResponse.body) as List;

        // Filter journal entries for current user
        final userJournalEntries =
            journalData.where((entry) => entry['userId'] == userId).toList();

        // Combine mood and journal entries
        List<MoodJournalEntry> combinedEntries = [];

        // Add mood entries
        for (var mood in moodData) {
          combinedEntries.add(MoodJournalEntry(
            id: mood['_id'],
            mood: mood['mood'],
            note: mood['note'] ?? '',
            content: '',
            createdAt: DateTime.parse(mood['date']),
            type: 'mood',
          ));
        }

        // Add journal entries
        for (var journal in userJournalEntries) {
          combinedEntries.add(MoodJournalEntry(
            id: journal['_id'],
            mood: '',
            note: '',
            content: journal['content'],
            createdAt: DateTime.parse(journal['entryDate']),
            type: 'journal',
          ));
        }

        // Sort by date (newest first)
        combinedEntries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        setState(() {
          moodJournalHistory = combinedEntries;
        });
      }
    } catch (e) {
      print('Error fetching mood journal history: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading history: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveMoodJournalEntry() async {
    if (_journalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a journal entry')),
      );
      return;
    }

    final userId = widget.userId;

    if (userId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save journal entry
      final journalResponse = await http.post(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/journal/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'title': 'Journal Entry',
          'content': _journalController.text.trim(),
          'mood': _selectedMood,
        }),
      );

      if (journalResponse.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Journal entry saved successfully!')),
          );

          // Clear form
          setState(() {
            _journalController.clear();
            _selectedMood = 'neutral';
          });

          // Refresh history
          await _fetchMoodJournalHistory();
        }
      } else {
        throw Exception('Failed to save journal entry');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithBottomNav(
      currentIndex: 1,
      userId: widget.userId,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Journal',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppTheme.primaryColor,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'New Entry'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildNewEntryTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Journal Entry Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.secondaryColor.withOpacity(0.1),
                  AppTheme.primaryColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.secondaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: AppTheme.secondaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Journal Entry',
                      style: AppTheme.headingMedium.copyWith(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Mood Selection
                Text(
                  'How are you feeling?',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _moods.map((mood) {
                    final isSelected = _selectedMood == mood['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMood = mood['name'];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? mood['color'].withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected
                                ? mood['color']
                                : Colors.grey.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              mood['emoji'],
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              mood['name'].toString().toUpperCase(),
                              style: TextStyle(
                                color: isSelected
                                    ? mood['color']
                                    : AppTheme.textSecondary,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: _journalController,
                  decoration: InputDecoration(
                    hintText:
                        'Write about your thoughts, experiences, or feelings...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: AppTheme.secondaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: AppTheme.secondaryColor, width: 2),
                    ),
                  ),
                  maxLines: 6,
                  minLines: 4,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveMoodJournalEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Save Entry',
                          style: AppTheme.headingMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _fetchMoodJournalHistory,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : moodJournalHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No entries yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start by creating your first mood or journal entry',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: moodJournalHistory.length,
                  itemBuilder: (context, index) {
                    final entry = moodJournalHistory[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: entry.type == 'mood'
                              ? AppTheme.primaryColor.withOpacity(0.2)
                              : AppTheme.secondaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: entry.type == 'mood'
                                      ? AppTheme.primaryColor.withOpacity(0.1)
                                      : AppTheme.secondaryColor
                                          .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  entry.type == 'mood' ? 'MOOD' : 'JOURNAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: entry.type == 'mood'
                                        ? AppTheme.primaryColor
                                        : AppTheme.secondaryColor,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat('MMM d, yyyy • h:mm a')
                                    .format(entry.createdAt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (entry.content.isNotEmpty) ...[
                            if (entry.mood.isNotEmpty)
                              const SizedBox(height: 12),
                            Text(
                              entry.content,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

class MoodJournalEntry {
  final String id;
  final String mood;
  final String note;
  final String content;
  final DateTime createdAt;
  final String type; // 'mood', 'journal', or 'combined'

  MoodJournalEntry({
    required this.id,
    required this.mood,
    required this.note,
    required this.content,
    required this.createdAt,
    required this.type,
  });
}
