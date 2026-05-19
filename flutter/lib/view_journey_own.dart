import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'add_journey_details.dart';

class ViewJourneysPage extends StatefulWidget {
  const ViewJourneysPage({super.key});

  @override
  State<ViewJourneysPage> createState() => _ViewJourneysPageState();
}

class _ViewJourneysPageState extends State<ViewJourneysPage> {
  List journeys = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchJourneys();
  }

  Future<void> fetchJourneys() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        setState(() {
          _errorMessage = "Server configuration missing";
          _isLoading = false;
        });
        return;
      }

      var response = await http.post(
        Uri.parse('$baseUrl/view_user_journeys/'),
        body: {'lid': lid},
      ).timeout(const Duration(seconds: 10));

      print('Response: ${response.body}');
      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'ok') {
        setState(() {
          journeys = jsonData['data'] ?? [];
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

  Future<void> deleteJourney(String journeyId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      var response = await http.post(
        Uri.parse('$baseUrl/delete_user_journey/'),
        body: {
          'journey_id': journeyId,
          'lid': lid,
        },
      );

      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journey deleted'),
            backgroundColor: Colors.green,
          ),
        );
        fetchJourneys(); // Refresh list
      } else {
        throw Exception(jsonData['message']);
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

  void _showDeleteDialog(String journeyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Journey'),
        content: const Text('Are you sure you want to delete this journey?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteJourney(journeyId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Journeys',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: fetchJourneys,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddJourneyPage()),
              );
              if (result == true) {
                fetchJourneys();
              }
            },
            tooltip: 'Add Journey',
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
            : journeys.isEmpty
            ? _buildEmptyState()
            : _buildJourneysList(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your journeys...',
            style: TextStyle(color: Colors.grey[600]),
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
              onPressed: fetchJourneys,
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

  Widget _buildEmptyState() {
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
            'No Journeys Added',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first journey to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddJourneyPage()),
              );
              if (result == true) {
                fetchJourneys();
              }
            },
            icon: const Icon(Icons.add_outlined),
            label: const Text('Add Journey'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneysList() {
    return RefreshIndicator(
      onRefresh: fetchJourneys,
      color: const Color(0xFFE91E63),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: journeys.length,
        itemBuilder: (context, index) {
          final journey = journeys[index];
          return _buildJourneyCard(journey);
        },
      ),
    );
  }

  Widget _buildJourneyCard(Map<String, dynamic> journey) {
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
              Colors.pink[50]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header with date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: const Color(0xFFE91E63),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM yyyy').format(
                            DateTime.parse(journey['date']),
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE91E63),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert_outlined,
                      color: Colors.grey[600],
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                        onTap: () => _showDeleteDialog(journey['id'].toString()),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Journey route
              Row(
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
                        height: 30,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          journey['toplace'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Time
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_outlined,
                      size: 16,
                      color: const Color(0xFFE91E63),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('hh:mm a').format(
                        DateTime.parse('2024-01-01 ${journey['time']}'),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}