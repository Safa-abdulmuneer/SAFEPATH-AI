import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class UserCreditScorePage extends StatefulWidget {
  const UserCreditScorePage({super.key});

  @override
  State<UserCreditScorePage> createState() => _UserCreditScorePageState();
}

class _UserCreditScorePageState extends State<UserCreditScorePage> {
  Map<String, dynamic> scoreData = {};
  bool _isLoading = true;
  String? _errorMessage;
  String? _userLid;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _userLid = prefs.getString('lid');
      _userEmail = prefs.getString('email') ?? 'User';
    });
    print("👤 User LID: $_userLid");
    print("👤 User Email: $_userEmail");
    await fetchCreditScore();
  }

  Future<void> fetchCreditScore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        throw Exception('Server configuration missing');
      }

      print("🔍 Fetching credit score for lid: $lid");
      print("🌐 URL: $baseUrl/get_user_score_by_lid/");

      var response = await http.post(
        Uri.parse('$baseUrl/get_user_score_by_lid/'),
        body: {'lid': lid},
      ).timeout(const Duration(seconds: 10));

      print("📥 Response status: ${response.statusCode}");
      print("📥 Response body: ${response.body}");

      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'success') {
        setState(() {
          scoreData = jsonData['data'];
          _isLoading = false;
        });
        print("✅ Score data loaded: ${scoreData['credit_score']}");
      } else {
        setState(() {
          _errorMessage = jsonData['message'] ?? 'Failed to load score';
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error: $e");
      setState(() {
        _errorMessage = 'Network error. Please check connection.';
        _isLoading = false;
      });
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 50) return Colors.green;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLevel(int score) {
    if (score >= 100) return 'Elite Guardian ⭐⭐⭐';
    if (score >= 50) return 'Trusted Guardian ⭐⭐';
    if (score >= 20) return 'Regular Guardian ⭐';
    if (score >= 10) return 'New Guardian ✨';
    return 'Beginner 🌱';
  }

  String _getNextLevel(int score) {
    if (score < 10) return '10';
    if (score < 20) return '20';
    if (score < 50) return '50';
    if (score < 100) return '100';
    return 'Max';
  }

  double _getProgressValue(int score) {
    if (score < 10) return score / 10;
    if (score < 20) return (score - 10) / 10;
    if (score < 50) return (score - 20) / 30;
    if (score < 100) return (score - 50) / 50;
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Credit Score',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: fetchCreditScore,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.pink[50]!,
              Colors.white,
            ],
          ),
        ),
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
            ? _buildErrorState()
            : _buildScoreCard(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your credit score...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchCreditScore,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    int score = scoreData['credit_score'] ?? 0;
    int totalSpots = scoreData['total_spots'] ?? 0;
    String username = scoreData['username'] ?? _userEmail ?? 'User';
    int userId = scoreData['user_id'] ?? 0;
    int lastUpdated = scoreData['last_updated'] ?? 0;

    // Convert blockchain timestamp to DateTime
    DateTime updatedTime = DateTime.fromMillisecondsSinceEpoch(lastUpdated * 1000);
    String formattedTime = DateFormat('dd MMM yyyy, hh:mm a').format(updatedTime);

    Color scoreColor = _getScoreColor(score);
    String scoreLevel = _getScoreLevel(score);
    String nextLevel = _getNextLevel(score);
    double progressValue = _getProgressValue(score);

    print("🎯 Displaying score: $score, spots: $totalSpots");

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.pink[100],
                      child: Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE91E63),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: scoreColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        scoreLevel,
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Credit Score Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE91E63),
                  Color(0xFF9C27B0),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'BLOCKCHAIN CREDIT SCORE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Verified Spots: $totalSpots',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Progress to next level
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Next Level Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$score / $nextLevel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  'Need ${int.parse(nextLevel) - score} more points to reach next level',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'User ID',
                  userId.toString(),
                  Icons.tag,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Blockchain',
                  'Active',
                  Icons.link,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Blockchain Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.link_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Blockchain Record',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last Updated:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // How to earn points
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'How to earn points',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('✓ Add dangerous spots', '+10 points when verified'),
          _buildInfoRow('✓ Report safe points', '+5 points when approved'),
          _buildInfoRow('✓ Share journey details', '+2 points per journey'),
          _buildInfoRow('✓ Help other users', '+1 point per interaction'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}