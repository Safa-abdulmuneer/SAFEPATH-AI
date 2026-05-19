import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'chat.dart';

// Import ChatPage


class ViewReceivedRequestsPage extends StatefulWidget {
  const ViewReceivedRequestsPage({super.key});

  @override
  State<ViewReceivedRequestsPage> createState() => _ViewReceivedRequestsPageState();
}

class _ViewReceivedRequestsPageState extends State<ViewReceivedRequestsPage> {
  List requests = [];
  bool _isLoading = true;
  String? _errorMessage;

  // For tracking loading state during accept/reject
  String? _processingRequestId;

  @override
  void initState() {
    super.initState();
    fetchReceivedRequests();
  }

  Future<void> fetchReceivedRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      print("🔍 Fetching received requests for lid: $lid");

      var response = await http.post(
        Uri.parse('$baseUrl/view_received_requests/'),
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

  Future<void> updateRequestStatus(String requestId, String status) async {
    setState(() {
      _processingRequestId = requestId;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      print("📝 Updating request $requestId to $status");

      var response = await http.post(
        Uri.parse('$baseUrl/update_request_status/'),
        body: {
          'request_id': requestId,
          'status': status,
          'lid': lid,
        },
      ).timeout(const Duration(seconds: 10));

      var jsonData = json.decode(response.body);

      if (jsonData['status'] == 'ok') {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Request ${status}ed successfully!'),
            backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // Refresh the list
        await fetchReceivedRequests();
      } else {
        throw Exception(jsonData['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      print("❌ Error updating request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _processingRequestId = null;
      });
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
                Colors.pink[50]!,
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

                    // Arrow
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

              // Sender Details
              const Text(
                'REQUESTER DETAILS',
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
                              request['sender']['name'][0].toUpperCase(),
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
                                request['sender']['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                request['sender']['place'] ?? 'Place not specified',
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

                    // Chat Option for Accepted Requests
                    if (request['status'] == 'accepted')
                      InkWell(
                        onTap: () async {
                          Navigator.pop(context); // Close dialog
                          // Navigate to Chat Page
                          SharedPreferences sh=await SharedPreferences.getInstance();
                          sh.setString("sid", request['sender']['ulid'].toString());
                          sh.setString("shopname", request['sender']['name'].toString());


                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyChatPage(title: '',
                                // request: request,
                                // otherUser: {
                                //   'name': request['sender']['name'],
                                //   'phone': request['sender']['phone'],
                                //   'email': request['sender']['email'],
                                //   'place': request['sender']['place'],
                                // },
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
                                      'Chat with Requester',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'Send message to ${request['sender']['name']}',
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
                        ),
                      ),

                    // Phone Option (for all status)
                    InkWell(
                      onTap: () => _makePhoneCall(request['sender']['phone']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                                    request['sender']['phone'] ?? 'Not available',
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
                    ),

                    if (request['sender']['email'] != null &&
                        request['sender']['email'].toString().isNotEmpty) ...[
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
                                  request['sender']['email'],
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

              // Action Buttons (only for pending requests)
              if (request['status'] == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _processingRequestId == request['id'].toString()
                            ? null
                            : () {
                          Navigator.pop(context);
                          updateRequestStatus(
                            request['id'].toString(),
                            'accepted',
                          );
                        },
                        icon: _processingRequestId == request['id'].toString()
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          _processingRequestId == request['id'].toString()
                              ? 'Processing...'
                              : 'Accept',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _processingRequestId == request['id'].toString()
                            ? null
                            : () {
                          Navigator.pop(context);
                          updateRequestStatus(
                            request['id'].toString(),
                            'rejected',
                          );
                        },
                        icon: _processingRequestId == request['id'].toString()
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Icon(Icons.cancel_outlined, size: 18),
                        label: Text(
                          _processingRequestId == request['id'].toString()
                              ? 'Processing...'
                              : 'Reject',
                        ),
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
                  ],
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
          'Received Requests',
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
            onPressed: fetchReceivedRequests,
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
                onPressed: fetchReceivedRequests,
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
              Icons.notifications_none_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Requests Received',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When someone requests to join your journey,\nthey will appear here',
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
      onRefresh: fetchReceivedRequests,
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

              // Requester info
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
                        request['sender']['name'][0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
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
                          request['sender']['name'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request['sender']['place'] ?? 'Place not specified',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
              const SizedBox(height: 12),

              // Action buttons based on status
              if (request['status'] == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _processingRequestId == request['id'].toString()
                            ? null
                            : () {
                          _showRequestDetailsDialog(request);
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View'),
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
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _processingRequestId == request['id'].toString()
                            ? null
                            : () {
                          updateRequestStatus(
                            request['id'].toString(),
                            'accepted',
                          );
                        },
                        icon: _processingRequestId == request['id'].toString()
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Icon(Icons.check_circle_outline, size: 16),
                        label: Text(
                          _processingRequestId == request['id'].toString()
                              ? ''
                              : 'Accept',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _processingRequestId == request['id'].toString()
                            ? null
                            : () {
                          updateRequestStatus(
                            request['id'].toString(),
                            'rejected',
                          );
                        },
                        icon: _processingRequestId == request['id'].toString()
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Icon(Icons.cancel_outlined, size: 16),
                        label: Text(
                          _processingRequestId == request['id'].toString()
                              ? ''
                              : 'Reject',
                        ),
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
                )
              else if (request['status'] == 'accepted')
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          SharedPreferences sh=await SharedPreferences.getInstance();
                          sh.setString("sid", request['sender']['ulid'].toString());
                          sh.setString("shopname", request['sender']['name'].toString());


                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyChatPage(title: '',
                                // request: request,
                                // otherUser: {
                                //   'name': request['sender']['name'],
                                //   'phone': request['sender']['phone'],
                                //   'email': request['sender']['email'],
                                //   'place': request['sender']['place'],
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
                  ],
                )
              else
              // For rejected or other status
                SizedBox(
                  width: double.infinity,
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
            ],
          ),
        ),
      ),
    );
  }
}