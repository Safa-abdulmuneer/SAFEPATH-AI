import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shecare/add_idea_page.dart';
import 'package:shecare/editIdea.dart';

class MyIdeasPage extends StatefulWidget {
  @override
  _MyIdeasPageState createState() => _MyIdeasPageState();
}

class _MyIdeasPageState extends State<MyIdeasPage> {
  List ideas = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  Future<void> fetchMyIdeas() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      SharedPreferences sp = await SharedPreferences.getInstance();
      String url = sp.getString('url') ?? "";
      String lid = sp.getString('lid') ?? "";

      if (url.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = "Backend URL missing";
          _isLoading = false;
        });
        return;
      }

      var res = await http.post(
        Uri.parse("$url/myapp/view_my_ideas/"),
        body: {"lid": lid},
      );

      if (res.statusCode == 200) {
        var jsonData = json.decode(res.body);
        if (jsonData['status'] == 'ok') {
          setState(() {
            ideas = jsonData['data'] ?? [];
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = jsonData['message'] ?? 'Failed to load your ideas';
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Server error: ${res.statusCode}';
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

  Future<void> _deleteIdea(int index) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Idea",
          style: TextStyle(
            color: Color(0xFF880E4F),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this idea? This action cannot be undone.",
          style: TextStyle(color: Colors.grey[700]),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                SharedPreferences sp = await SharedPreferences.getInstance();
                String url = sp.getString('url') ?? "";

                await http.post(
                  Uri.parse("$url/myapp/delete_idea/"),
                  body: {"idea_id": ideas[index]['id'].toString()},
                );

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Idea deleted successfully"),
                    backgroundColor: Color(0xFFE91E63),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );

                // Refresh list
                await fetchMyIdeas();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to delete idea: $e"),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("Delete"),
          ),
        ],
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
                  height: 150,
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFE91E63)),
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
                                size: 36,
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

              // Stats and Actions Row
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
                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_border,
                          color: Colors.pink[400],
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          idea['likes']?.toString() ?? '0',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(
                          Icons.comment_outlined,
                          color: Colors.pink[400],
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          idea['comments']?.toString() ?? '0',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    Spacer(),

                    // Actions
                    Row(
                      children: [
                        // Edit Button
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFE91E63).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditIdeaPage(
                                    ideaId: idea['id'],
                                    currentIdea: idea['idea'],
                                  ),
                                ),
                              );

                              if (updated == true) {
                                await fetchMyIdeas();
                              }
                            },
                            icon: Icon(
                              Icons.edit_outlined,
                              color: Color(0xFFE91E63),
                              size: 20,
                            ),
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(),
                          ),
                        ),
                        SizedBox(width: 8),

                        // Delete Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            onPressed: () => _deleteIdea(index),
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            padding: EdgeInsets.all(8),
                            constraints: BoxConstraints(),
                          ),
                        ),
                      ],
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
    fetchMyIdeas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "My Ideas",
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
            icon: Icon(Icons.add, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddIdeaPage()),
              ).then((_) => fetchMyIdeas());
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
                    "My Contributions",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF880E4F),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Manage and edit the ideas you've shared with the community",
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
                      "Loading your ideas...",
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
                      onPressed: fetchMyIdeas,
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
                      "Start sharing your innovative ideas with the community!",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => AddIdeaPage()),
                        ).then((_) => fetchMyIdeas());
                      },
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
                          Icon(Icons.add, size: 20),
                          SizedBox(width: 8),
                          Text("Create Your First Idea"),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: fetchMyIdeas,
                color: Color(0xFFE91E63),
                backgroundColor: Colors.white,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Summary Card
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
                                Icons.person_outline,
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
                                    "Your Ideas: ${ideas.length}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF880E4F),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "You can edit or delete your ideas anytime",
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
                          Map<String, dynamic>.from(ideas[index]),
                          index,
                        ),
                      ),

                      // Tip Card
                      if (ideas.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(top: 16),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.pink[50],
                            borderRadius:
                            BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.pink[100]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFFE91E63),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Tip: Your ideas are visible to the community. Keep them updated and relevant!",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFC2185B),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddIdeaPage()),
          ).then((_) => fetchMyIdeas());
        },
        backgroundColor: Color(0xFFE91E63),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Icon(Icons.add, size: 28),
      ),
    );
  }
}