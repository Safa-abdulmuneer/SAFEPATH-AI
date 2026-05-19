import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shecare/myIdeas.dart';

class ViewAllIdeasPage extends StatefulWidget {
  @override
  _ViewAllIdeasPageState createState() => _ViewAllIdeasPageState();
}

class _ViewAllIdeasPageState extends State<ViewAllIdeasPage> {
  List ideas = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  Future<void> fetchIdeas() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      SharedPreferences sp = await SharedPreferences.getInstance();
      String url = sp.getString('url') ?? '';
      String lid = sp.getString('lid') ?? '';

      if (url.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = "Backend URL missing";
          _isLoading = false;
        });
        return;
      }

      var response = await http.post(
        Uri.parse('$url/myapp/view_all_ideas/'),
        body: {'lid': lid},
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        if (jsonData['status'] == 'ok') {
          setState(() {
            ideas = jsonData['data'] ?? [];
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = jsonData['message'] ?? 'Failed to load ideas';
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Connection error: $e';
      });
      print("❌ Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Color(0xFFE91E63),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildIdeaCard(Map<String, dynamic> idea, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.pink[100]!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFFE91E63).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: Color(0xFFE91E63),
                      size: 22,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          idea['username']?.toString() ?? 'Anonymous',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF880E4F),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Shared idea',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (idea['timestamp'] != null)
                    Text(
                      idea['timestamp'].toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),

              // Idea content
              Text(
                idea['idea']?.toString() ?? 'No content',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                  height: 1.5,
                ),
              ),

              // Image if exists
              if (idea['image'] != null && idea['image'].isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 16),
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.pink[50],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      '${idea['image']}',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.pink[50],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.pink[300],
                                size: 48,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Image unavailable',
                                style: TextStyle(
                                  color: Colors.pink[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Actions row
              Container(
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        // Like action
                        _showSnackBar("Liked idea", isError: false);
                      },
                      icon: Icon(
                        Icons.favorite_border,
                        color: Color(0xFFE91E63),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: 4),
                    Text(
                      idea['likes']?.toString() ?? '0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 24),
                    IconButton(
                      onPressed: () {
                        // Comment action
                        _showSnackBar("Comments feature coming soon", isError: false);
                      },
                      icon: Icon(
                        Icons.comment_outlined,
                        color: Color(0xFFE91E63),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                    SizedBox(width: 4),
                    Text(
                      idea['comments']?.toString() ?? '0',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () {
                        // Share action
                        _showSnackBar("Share feature coming soon", isError: false);
                      },
                      icon: Icon(
                        Icons.share_outlined,
                        color: Color(0xFFE91E63),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
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

  @override
  void initState() {
    super.initState();
    fetchIdeas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Community Ideas",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFE91E63),
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyIdeasPage()),
              );
            },
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Community Ideas Hub",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF880E4F),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Explore innovative ideas, suggestions, and improvements shared by our community members",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: _isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFE91E63),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Loading ideas...",
                      style: TextStyle(
                        color: Color(0xFF880E4F),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
                  : _hasError
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    SizedBox(height: 16),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: fetchIdeas,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE91E63),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, size: 20),
                          SizedBox(width: 8),
                          Text("Try Again"),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  : ideas.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 64,
                      color: Colors.pink[300],
                    ),
                    SizedBox(height: 16),
                    Text(
                      "No ideas yet",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF880E4F),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Be the first to share your idea!",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 24),

                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: fetchIdeas,
                color: Color(0xFFE91E63),
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Ideas Count Card
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink[50]!,
                              Colors.purple[50]!
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.pink[100]!, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFFE91E63),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.lightbulb_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Total Ideas: ${ideas.length}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF880E4F),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Browse through innovative ideas from our community",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Ideas List
                      ...List.generate(
                        ideas.length,
                            (index) => _buildIdeaCard(
                          Map<String, dynamic>.from(
                              ideas[index]),
                          index,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }
}