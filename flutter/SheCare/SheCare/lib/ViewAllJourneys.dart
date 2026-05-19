import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewAllJourneysPage extends StatefulWidget {
  const ViewAllJourneysPage({super.key});

  @override
  State<ViewAllJourneysPage> createState() => _ViewAllJourneysPageState();
}

class _ViewAllJourneysPageState extends State<ViewAllJourneysPage> with SingleTickerProviderStateMixin {
  List journeys = [];
  List filteredJourneys = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search
  final TextEditingController searchCtrl = TextEditingController();
  String searchQuery = '';

  // Tab controller
  late TabController _tabController;

  // Stats
  int totalCount = 0;
  int todayCount = 0;

  // Request status
  Set<int> requestedJourneys = {}; // Track which journeys have been requested

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAllJourneys();
    searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    searchCtrl.removeListener(_onSearchChanged);
    searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      searchQuery = searchCtrl.text.toLowerCase();
      _filterJourneys();
    });
  }

  void _filterJourneys() {
    if (searchQuery.isEmpty) {
      filteredJourneys = List.from(journeys);
    } else {
      filteredJourneys = journeys.where((journey) {
        return journey['fromplace'].toString().toLowerCase().contains(searchQuery) ||
            journey['toplace'].toString().toLowerCase().contains(searchQuery) ||
            journey['user']['name'].toString().toLowerCase().contains(searchQuery) ||
            journey['user']['place'].toString().toLowerCase().contains(searchQuery);
      }).toList();
    }
  }

  Future<void> fetchAllJourneys() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty) {
        throw Exception('Server configuration missing');
      }

      var response = await http.post(
        Uri.parse('$baseUrl/view_all_users_journeys/'),
        body: {'lid': lid},
      ).timeout(const Duration(seconds: 10));

      print('Response: ${response.body}');
      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'ok') {
        setState(() {
          journeys = jsonData['data'] ?? [];
          totalCount = jsonData['total_count'] ?? 0;
          _filterJourneys();

          // Calculate today's count
          String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          todayCount = journeys.where((j) => j['date'] == today).length;

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = jsonData['message'] ?? 'Failed to load journeys';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error. Please check connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendJourneyRequest(String journeyId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      var response = await http.post(
        Uri.parse('$baseUrl/send_journey_request/'),
        body: {
          'journey_id': journeyId,
          'sender_lid': lid,
        },
      );

      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'ok') {
        setState(() {
          requestedJourneys.add(int.parse(journeyId));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Request sent successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${jsonData['message']}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRequestDialog(String journeyId, String fromPlace, String toPlace) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_outlined,
                color: Color(0xFFE91E63),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Send Journey Request',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Do you want to join this journey?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route_outlined, color: Color(0xFFE91E63), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fromPlace,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(Icons.arrow_downward, size: 14, color: Colors.grey),
                        Text(
                          toPlace,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendJourneyRequest(journeyId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer')),
        );
      }
    } catch (e) {
      print('Error making call: $e');
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    user['name'][0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE91E63),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['place'] ?? 'Place not specified',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.phone_outlined, color: Color(0xFFE91E63)),
              title: const Text('Phone Number'),
              subtitle: Text(user['phone'] ?? 'Not available'),
              trailing: IconButton(
                icon: const Icon(Icons.call_outlined, color: Colors.green),
                onPressed: user['phone'] != null
                    ? () => _makePhoneCall(user['phone'].toString())
                    : null,
              ),
            ),
            if (user['email'] != null && user['email'].toString().isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email_outlined, color: Color(0xFFE91E63)),
                title: const Text('Email'),
                subtitle: Text(user['email'].toString()),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community Journeys',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('All ($totalCount)'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.today_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Today ($todayCount)'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: fetchAllJourneys,
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
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by place or person...',
                    prefixIcon: const Icon(Icons.search_outlined, color: Color(0xFFE91E63)),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear_outlined),
                      onPressed: () => searchCtrl.clear(),
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.pink[200]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.pink[200]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE91E63), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                  ? _buildErrorState()
                  : TabBarView(
                controller: _tabController,
                children: [
                  _buildJourneysList(filteredJourneys),
                  _buildJourneysList(
                      journeys.where((j) => j['date'] == DateFormat('yyyy-MM-dd').format(DateTime.now())).toList()
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
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
              onPressed: fetchAllJourneys,
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

  Widget _buildJourneysList(List journeyList) {
    if (journeyList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty ? 'No matching journeys found' : 'No journeys available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchAllJourneys,
      color: const Color(0xFFE91E63),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: journeyList.length,
        itemBuilder: (context, index) {
          final journey = journeyList[index];
          return _buildJourneyCard(journey);
        },
      ),
    );
  }

  Widget _buildJourneyCard(Map<String, dynamic> journey) {
    final user = journey['user'];
    bool isToday = journey['date'] == DateFormat('yyyy-MM-dd').format(DateTime.now());
    bool hasRequested = requestedJourneys.contains(journey['id']);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              isToday ? Colors.pink[50]! : Colors.purple[50]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header with user info and date
              Row(
                children: [
                  // User avatar
                  GestureDetector(
                    onTap: () => _showUserDetails(user),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE91E63).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user['name'][0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E63),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // User name and place
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'] ?? 'Unknown User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user['place'] ?? 'Place not specified',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Date badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.pink : Colors.purple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isToday ? 'Today' : DateFormat('dd MMM').format(
                        DateTime.parse(journey['date']),
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Journey route
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE91E63),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journey['fromplace'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Text(
                          journey['toplace'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Time
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          size: 14,
                          color: const Color(0xFFE91E63),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('hh:mm a').format(
                            DateTime.parse('2024-01-01 ${journey['time']}'),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showUserDetails(user),
                      icon: const Icon(Icons.person_outline, size: 16),
                      label: const Text('View User'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE91E63),
                        side: const BorderSide(color: Color(0xFFE91E63)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (hasRequested)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Request Sent',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showRequestDialog(
                          journey['id'].toString(),
                          journey['fromplace'],
                          journey['toplace'],
                        ),
                        icon: const Icon(Icons.send_outlined, size: 16),
                        label: const Text('Send Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}