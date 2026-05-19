import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SOSHistoryPage extends StatefulWidget {
  const SOSHistoryPage({super.key});

  @override
  State<SOSHistoryPage> createState() => _SOSHistoryPageState();
}

class _SOSHistoryPageState extends State<SOSHistoryPage> {
  List<dynamic> sosAlerts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedAlertId;

  @override
  void initState() {
    super.initState();
    fetchSOSAlerts();
  }

  Future<void> fetchSOSAlerts() async {
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

      print("🔍 Fetching SOS alerts for lid: $lid");

      var response = await http.post(
        Uri.parse('$baseUrl/get-user-sos-alerts/'),
        body: {'lid': lid},
      ).timeout(const Duration(seconds: 10));

      print("📥 Response: ${response.body}");
      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'success') {
        setState(() {
          sosAlerts = jsonData['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = jsonData['message'] ?? 'Failed to load SOS alerts';
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

  Future<void> deleteSOSAlert(String alertId) async {
    // Show confirmation dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete SOS Alert'),
        content: const Text('Are you sure you want to delete this SOS alert? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _selectedAlertId = alertId;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      var response = await http.post(
        Uri.parse('$baseUrl/delete-sos-alert/$alertId/'),
        body: {'lid': lid},
      ).timeout(const Duration(seconds: 10));

      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'success') {
        // Remove from list
        setState(() {
          sosAlerts.removeWhere((alert) => alert['id'].toString() == alertId);
          _selectedAlertId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ SOS alert deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(jsonData['message']);
      }
    } catch (e) {
      setState(() {
        _selectedAlertId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> resolveSOSAlert(String alertId) async {
    setState(() {
      _selectedAlertId = alertId;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      var response = await http.post(
        Uri.parse('$baseUrl/resolve-sos-alert/$alertId/'),
        body: {'lid': lid},
      ).timeout(const Duration(seconds: 10));

      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'success') {
        // Update status in list
        setState(() {
          int index = sosAlerts.indexWhere((alert) => alert['id'].toString() == alertId);
          if (index != -1) {
            sosAlerts[index]['status'] = 'resolved';
          }
          _selectedAlertId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ SOS alert marked as resolved'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception(jsonData['message']);
      }
    } catch (e) {
      setState(() {
        _selectedAlertId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openMap(String lat, String lng) async {
    final Uri googleMapsUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng"
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open map: $e')),
      );
    }
  }

  String _formatDate(String timestamp) {
    try {
      DateTime dateTime = DateTime.parse(timestamp);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.red;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My SOS History',
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
            icon: const Icon(Icons.refresh_outlined, color: Colors.white),
            onPressed: fetchSOSAlerts,
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
            : sosAlerts.isEmpty
            ? _buildEmptyState()
            : _buildSOSList(),
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
          Text('Loading SOS history...'),
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
              onPressed: fetchSOSAlerts,
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
            Icons.warning_amber_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No SOS Alerts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When you trigger SOS alerts, they will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSList() {
    return RefreshIndicator(
      onRefresh: fetchSOSAlerts,
      color: const Color(0xFFE91E63),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sosAlerts.length,
        itemBuilder: (context, index) {
          final alert = sosAlerts[index];
          final bool isProcessing = _selectedAlertId == alert['id'].toString();

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    _getStatusColor(alert['status']).withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Header with status and date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(alert['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              alert['status'] == 'active'
                                  ? Icons.warning_amber_rounded
                                  : Icons.check_circle_outline,
                              size: 14,
                              color: _getStatusColor(alert['status']),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              alert['status'].toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(alert['status']),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(alert['timestamp']),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.pink.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFFE91E63),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${alert['latitude']}, ${alert['longitude']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
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
                      // View on Map Button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openMap(alert['latitude'], alert['longitude']),
                          icon: const Icon(Icons.map_outlined, size: 16),
                          label: const Text('Map'),
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

                      // Resolve Button (only for active alerts)

                      const SizedBox(width: 8),

                      // Delete Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () => deleteSOSAlert(alert['id'].toString()),
                          icon: isProcessing
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Icon(Icons.delete_outline, size: 16),
                          label: Text(isProcessing ? '' : 'Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
          );
        },
      ),
    );
  }
}