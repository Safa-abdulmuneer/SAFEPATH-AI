import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat.dart';

// Import ChatPage (make sure path is correct)


class ViewSentRequestsPage extends StatefulWidget {
  const ViewSentRequestsPage({super.key});

  @override
  State<ViewSentRequestsPage> createState() => _ViewSentRequestsPageState();
}

class _ViewSentRequestsPageState extends State<ViewSentRequestsPage> {
  List requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchSentRequests();
  }

  Future<void> fetchSentRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      print("🔍 Fetching sent requests for lid: $lid");

      var response = await http.post(
        Uri.parse('$baseUrl/view_sent_requests/'),
        body: {'lid': lid},
      ).timeout(const Duration(seconds: 10));

      print("📥 Response: ${response.body}");
      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'ok') {
        setState(() {
          requests = jsonData['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = jsonData['message'] ?? 'Failed to load requests';
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

  Future<void> cancelRequest(String requestId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performCancelRequest(requestId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _performCancelRequest(String requestId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      var response = await http.post(
        Uri.parse('$baseUrl/delete_request/'),
        body: {
          'request_id': requestId,
          'lid': lid,
        },
      ).timeout(const Duration(seconds: 10));

      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Request cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        fetchSentRequests();
      } else {
        throw Exception(jsonData['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      print('Error making call: $e');
    }
  }

  void _showRequestDetailsDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                _getStatusColor(request['status']).withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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

              // Status Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(request['status']),
                        color: _getStatusColor(request['status']),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        request['status'].toString().toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(request['status']),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Journey Details
              const Text(
                'JOURNEY DETAILS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // From
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_outlined,
                            color: Colors.green,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'From',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                request['journey']['fromplace'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Icon(Icons.arrow_downward, size: 16, color: Colors.grey),
                    const SizedBox(height: 12),
                    // To
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
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'To',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                request['journey']['toplace'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Date and Time
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: const Color(0xFFE91E63),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy').format(
                              DateTime.parse(request['journey']['date']),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            size: 18,
                            color: const Color(0xFFE91E63),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('hh:mm a').format(
                              DateTime.parse('2024-01-01 ${request['journey']['time']}'),
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Owner Details
              const Text(
                'JOURNEY OWNER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Name
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.pink.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              request['journey']['owner']['name'][0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE91E63),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request['journey']['owner']['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                request['journey']['owner']['place'] ?? 'Place not specified',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Chat Option (for accepted requests)
                    if (request['status'] == 'accepted')
                      InkWell(
                        onTap: () async {



                          Navigator.pop(context); // Close dialog
                          // Navigate to Chat Page

                          SharedPreferences sh=await SharedPreferences.getInstance();
                          sh.setString("sid", request['journey']['owner']['ulid'].toString());
                          sh.setString("shopname", request['journey']['owner']['name'].toString());
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyChatPage(title: '',
                                // request: request,
                                // otherUser: {
                                //   'name': request['journey']['owner']['name'],
                                //   'phone': request['journey']['owner']['phone'],
                                //   'email': request['journey']['owner']['email'],
                                //   'place': request['journey']['owner']['place'],
                                // },
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.chat_outlined,
                                size: 18,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Chat with Owner',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    'Send message to ${request['journey']['owner']['name']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Phone option for non-accepted requests
                      InkWell(
                        onTap: () => _makePhoneCall(request['journey']['owner']['phone']),
                        child: Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 18,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Phone',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    request['journey']['owner']['phone'] ?? 'Not available',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.call_outlined,
                              size: 18,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (request['journey']['owner']['email'] != null &&
                        request['journey']['owner']['email'].toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  request['journey']['owner']['email'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Cancel button (only for pending requests)
              if (request['status'] == 'pending')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      cancelRequest(request['id'].toString());
                    },
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel Request'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Close button
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                ),
                child: const Center(
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'pending':
      default:
        return Icons.hourglass_empty_outlined;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Sent Requests',
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
            onPressed: fetchSentRequests,
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
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
        ),
      );
    }

    if (_errorMessage != null) {
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
                onPressed: fetchSentRequests,
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

    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Requests Sent',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When you send requests to join journeys,\nthey will appear here',
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

    return RefreshIndicator(
      onRefresh: fetchSentRequests,
      color: const Color(0xFFE91E63),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showRequestDetailsDialog(request),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                _getStatusColor(request['status']).withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request['status']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(request['status']),
                          size: 14,
                          color: _getStatusColor(request['status']),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusText(request['status']),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(request['status']),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('dd MMM').format(
                      DateTime.parse(request['request_date']),
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Journey route
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            request['journey']['fromplace'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            request['journey']['toplace'],
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.circle,
                          size: 8,
                          color: Color(0xFFE91E63),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Owner name
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Owner: ${request['journey']['owner']['name']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRequestDetailsDialog(request),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE91E63),
                        side: const BorderSide(color: Color(0xFFE91E63)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // Show different button based on status
                  if (request['status'] == 'accepted') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          SharedPreferences sh=await SharedPreferences.getInstance();
                          sh.setString("sid", request['journey']['owner']['ulid'].toString());
                          sh.setString("shopname", request['journey']['owner']['name'].toString());
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyChatPage(title: '',
                                // request: request,
                                // otherUser: {
                                //   'name': request['journey']['owner']['name'],
                                //   'phone': request['journey']['owner']['phone'],
                                //   'email': request['journey']['owner']['email'],
                                //   'place': request['journey']['owner']['place'],
                                // },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_outlined, size: 16),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ] else if (request['status'] == 'pending') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => cancelRequest(request['id'].toString()),
                        icon: const Icon(Icons.cancel_outlined, size: 16),
                        label: const Text('Cancel'),
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
                  // For rejected status, no second button
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}