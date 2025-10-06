import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:myapp/theme/app_theme.dart';

class TherapistTestResultsScreen extends StatefulWidget {
  final String therapistId;
  final String?
      patientId; // Optional - if provided, show results for specific patient

  const TherapistTestResultsScreen({
    Key? key,
    required this.therapistId,
    this.patientId,
  }) : super(key: key);

  @override
  State<TherapistTestResultsScreen> createState() =>
      _TherapistTestResultsScreenState();
}

class _TherapistTestResultsScreenState
    extends State<TherapistTestResultsScreen> {
  List<Map<String, dynamic>> _testResults = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTestResults();
  }

  Future<void> _fetchTestResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String url;
      if (widget.patientId != null) {
        // Get results for specific patient
        url =
            'http:// 192.168.2.102:3000/api/test-results/user/${widget.patientId}?requesterId=${widget.therapistId}&requesterRole=therapist';
      } else {
        // Get results for all patients of this therapist
        url =
            'http:// 192.168.2.102:3000/api/test-results/therapist/${widget.therapistId}/patients';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _testResults = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _error =
              'Access denied. You can only view test results for patients you have appointments with.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load test results: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading test results: $e';
        _isLoading = false;
      });
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'mild':
        return Colors.orange;
      case 'moderate':
        return Colors.deepOrange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildTestResultCard(Map<String, dynamic> result) {
    final DateTime testDate = DateTime.parse(result['testDate']);
    final String formattedDate = DateFormat('MMM dd, yyyy').format(testDate);
    final String severity = result['severity'] ?? 'Unknown';
    final int score = result['score'] ?? 0;
    final int maxScore = result['maxScore'] ?? 30;
    final String userName = result['userId']?['username'] ?? 'Unknown User';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    userName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSeverityColor(severity).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getSeverityColor(severity)),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      color: _getSeverityColor(severity),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  formattedDate,
                  style: AppTheme.bodyMedium.copyWith(color: Colors.grey[600]),
                ),
                const Spacer(),
                Icon(Icons.assessment, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '$score / $maxScore',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getSeverityColor(severity),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: score / maxScore,
              backgroundColor: Colors.grey[300],
              valueColor:
                  AlwaysStoppedAnimation<Color>(_getSeverityColor(severity)),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              'Test Type: ${result['testType']?.toString().toUpperCase() ?? 'UNKNOWN'}',
              style: AppTheme.bodySmall.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _showTestDetails(result),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTestDetails(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Test Result Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Patient: ${result['userId']?['username'] ?? 'Unknown'}'),
                const SizedBox(height: 8),
                Text(
                    'Test Date: ${DateFormat('MMM dd, yyyy HH:mm').format(DateTime.parse(result['testDate']))}'),
                const SizedBox(height: 8),
                Text('Score: ${result['score']} / ${result['maxScore']}'),
                const SizedBox(height: 8),
                Text('Severity: ${result['severity']}'),
                const SizedBox(height: 16),
                const Text('Responses:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...((result['responses'] as List<dynamic>?) ?? [])
                    .map<Widget>((response) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                        'Q${response['questionIndex'] + 1}: ${response['answer']} (${response['score']} pts)'),
                  );
                }).toList(),
              ],
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patientId != null
              ? 'Patient Test Results'
              : 'All Patient Test Results',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTestResults,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyLarge
                            .copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchTestResults,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _testResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No test results found',
                            style: AppTheme.bodyLarge
                                .copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Test results will appear here once your patients complete anxiety/depression assessments.',
                            textAlign: TextAlign.center,
                            style: AppTheme.bodyMedium
                                .copyWith(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _testResults.length,
                      itemBuilder: (context, index) {
                        return _buildTestResultCard(_testResults[index]);
                      },
                    ),
    );
  }
}
