import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ViewReplyPage extends StatefulWidget {
  const ViewReplyPage({super.key});

  @override
  State<ViewReplyPage> createState() => _ViewReplyPageState();
}

class _ViewReplyPageState extends State<ViewReplyPage> {
  List replies = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = "";
  String _baseUrl = "";

  Future<void> loadReplies() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (_baseUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = "Backend URL not configured";
          _isLoading = false;
        });
        return;
      }

      var resp = await http.post(
        Uri.parse("$_baseUrl/myapp/user_view_reply/"),
        body: {'lid': lid},
      );

      var jsonData = json.decode(resp.body);

      if (jsonData['status'] == 'ok') {
        setState(() {
          replies = jsonData['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = "Failed to load replies: ${jsonData['message']}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = "Connection error: $e";
        _isLoading = false;
      });
    }
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.pending_outlined;
        label = 'Pending';
        break;
      case 'replied':
        chipColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle_outlined;
        label = 'Replied';
        break;
      case 'processing':
        chipColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        icon = Icons.schedule_outlined;
        label = 'Processing';
        break;
      case 'resolved':
        chipColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.done_all_outlined;
        label = 'Resolved';
        break;
      default:
        chipColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        icon = Icons.help_outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadReplies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Complaint Responses",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFE91E63),
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: loadReplies,
            tooltip: "Refresh",
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
            ),
            const SizedBox(height: 16),
            Text(
              "Loading responses...",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
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
              _errorMessage,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: loadReplies,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE91E63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_outlined),
              label: const Text("Try Again"),
            ),
          ],
        ),
      );
    }

    if (replies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 72,
              color: Colors.pink[200],
            ),
            const SizedBox(height: 20),
            Text(
              "No responses yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF880E4F),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "You haven't received any responses to your complaints yet. Check back later for updates.",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadReplies,
      color: Color(0xFFE91E63),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: replies.length,
        itemBuilder: (context, index) {
          var reply = replies[index];
          return _buildReplyCard(reply, index);
        },
      ),
    );
  }

  Widget _buildReplyCard(Map<String, dynamic> reply, int index) {
    bool hasReply = reply['reply'] != null && reply['reply'].isNotEmpty;
    bool isResolved = (reply['status']?.toString().toLowerCase() == 'resolved');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isResolved ? Colors.green[100]! : Colors.pink[100]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(reply['status'] ?? 'Pending'),
                Text(
                  reply['date'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Police Officer Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_pin_outlined,
                    size: 20,
                    color: Color(0xFFE91E63),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Police Officer",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      Text(
                        reply['police_name'] ?? 'Unknown Officer',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Complaint Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.report_problem_outlined,
                        size: 16,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Your Complaint:",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reply['complaint'] ?? 'No complaint text',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reply Section
            if (hasReply)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isResolved ? Colors.green[50] : Colors.pink[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isResolved ? Colors.green[100]! : Color(0xFFF8BBD0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isResolved
                              ? Icons.check_circle_outlined
                              : Icons.message_outlined,
                          size: 16,
                          color: isResolved ? Colors.green[600] : Color(0xFFE91E63),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isResolved ? "Resolution:" : "Response:",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isResolved ? Colors.green[700] : Color(0xFFC2185B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reply['reply'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.4,
                      ),
                    ),
                    if (isResolved)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 14,
                              color: Colors.green[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "This case has been resolved",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange[100]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: Colors.orange[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Waiting for response from authorities...",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}