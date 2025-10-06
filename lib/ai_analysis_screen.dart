import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/theme/app_theme.dart';
import 'dart:async';

class AIAnalysisScreen extends StatefulWidget {
  final String userId;

  const AIAnalysisScreen({super.key, required this.userId});

  @override
  State<AIAnalysisScreen> createState() => _AIAnalysisScreenState();
}

class _AIAnalysisScreenState extends State<AIAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();

  bool _isAnalyzing = false;
  bool _isLoadingHistory = false;
  Map<String, dynamic>? _currentAnalysis;
  List<Map<String, dynamic>> _analysisHistory = [];
  Timer? _realTimeTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnalysisHistory();

    // Set up real-time analysis
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _realTimeTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    // Cancel previous timer
    _realTimeTimer?.cancel();

    // Start new timer for real-time analysis
    if (_textController.text.trim().isNotEmpty) {
      _realTimeTimer = Timer(const Duration(seconds: 2), () {
        _performRealTimeAnalysis();
      });
    }
  }

  Future<void> _performRealTimeAnalysis() async {
    if (_textController.text.trim().isEmpty) return;

    final userId = widget.userId;
    debugPrint('🔍 Real-time analysis - User ID: $userId');

    if (userId.isEmpty) {
      debugPrint('❌ User ID is empty');
      return;
    }

    try {
      final url =
          'https://mindease-backend-production.up.railway.app/api/ai-analysis/realtime/$userId';
      debugPrint('📡 Making request to: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': _textController.text.trim()}),
      );

      debugPrint('📊 Response status: ${response.statusCode}');
      debugPrint('📊 Response body: ${response.body}');

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentAnalysis = data['result']['analysis'];
        });
        debugPrint('✅ Real-time analysis completed successfully');
      } else {
        debugPrint('❌ Real-time analysis failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Real-time analysis error: $e');
    }
  }

  Future<void> _analyzeText() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some text to analyze')),
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
      _isAnalyzing = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'https://mindease-backend-production.up.railway.app/api/ai-analysis/analyze/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': _textController.text.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _currentAnalysis = data['result']['analysis'];
        });

        // Refresh history
        await _loadAnalysisHistory();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Analysis completed successfully!')),
          );
        }
      } else {
        throw Exception('Failed to analyze text');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error analyzing text: $e')),
        );
      }
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _loadAnalysisHistory() async {
    final userId = widget.userId;
    if (userId.isEmpty) return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http:// 192.168.2.102:3000/api/ai-analysis/history/$userId?limit=20'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _analysisHistory = List<Map<String, dynamic>>.from(data['data']);
        });
      }
    } catch (e) {
      debugPrint('Error loading analysis history: $e');
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
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
                        'AI Journal Analysis',
                        style: AppTheme.headingMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                      child: const Icon(
                        Icons.psychology,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  boxShadow: AppTheme.softShadow,
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textSecondary,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.analytics),
                      text: 'Analyze',
                    ),
                    Tab(
                      icon: Icon(Icons.history),
                      text: 'History',
                    ),
                  ],
                ),
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAnalyzeTab(),
                    _buildHistoryTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text Input Card
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      'Enter your journal text',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText:
                        'Write about your thoughts, feelings, or experiences...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide: BorderSide(
                          color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      borderSide:
                          BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                  ),
                  maxLines: 6,
                  minLines: 4,
                ),
                const SizedBox(height: AppTheme.spacingM),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isAnalyzing ? null : _analyzeText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spacingM),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      ),
                    ),
                    child: _isAnalyzing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.psychology),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                'Analyze with AI',
                                style: AppTheme.bodyLarge.copyWith(
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
          ),

          const SizedBox(height: AppTheme.spacingL),

          // Analysis Results
          if (_currentAnalysis != null) _buildAnalysisResults(),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadAnalysisHistory,
      child: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator())
          : _analysisHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: AppTheme.spacingM),
                      Text(
                        'No analysis history yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: AppTheme.spacingS),
                      Text(
                        'Start analyzing your journal entries to see insights here',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: _analysisHistory.length,
                  itemBuilder: (context, index) {
                    final analysis = _analysisHistory[index];
                    return _buildHistoryCard(analysis);
                  },
                ),
    );
  }

  Widget _buildAnalysisResults() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'AI Analysis Results',
                style: AppTheme.headingSmall.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),

          // Mental Health Status
          _buildAnalysisCard(
            'Mental Health Status',
            _currentAnalysis!['mentalHealthStatus']['primary']
                .toString()
                .toUpperCase(),
            Icons.psychology,
            _getStatusColor(_currentAnalysis!['mentalHealthStatus']['primary']),
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Sentiment Score
          _buildAnalysisCard(
            'Sentiment',
            _currentAnalysis!['sentimentScore']['label']
                .toString()
                .toUpperCase(),
            Icons.sentiment_satisfied,
            _getSentimentColor(_currentAnalysis!['sentimentScore']['label']),
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Risk Level
          _buildAnalysisCard(
            'Risk Level',
            _currentAnalysis!['riskLevel']['level'].toString().toUpperCase(),
            Icons.warning,
            _getRiskColor(_currentAnalysis!['riskLevel']['level']),
          ),

          const SizedBox(height: AppTheme.spacingM),

          // Recommendations
          if (_currentAnalysis!['recommendations'] != null)
            _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: AppTheme.headingSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations =
        List<String>.from(_currentAnalysis!['recommendations']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: AppTheme.secondaryColor,
              size: 24,
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              'Recommendations',
              style: AppTheme.headingSmall.copyWith(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingS),
        ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppTheme.secondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      rec,
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> analysis) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateTime.parse(analysis['date']).toString().split(' ')[0],
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingS,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Text(
                  analysis['analysis']['mentalHealthStatus']['primary']
                      .toString()
                      .toUpperCase(),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            analysis['content'].toString().length > 100
                ? '${analysis['content'].toString().substring(0, 100)}...'
                : analysis['content'].toString(),
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'anxiety':
        return Colors.orange;
      case 'depression':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.green;
    }
  }
}
