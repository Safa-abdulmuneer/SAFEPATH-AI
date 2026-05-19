import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shecare/EditDagerousPage.dart';
import 'addDangerousPage.dart';

class DangerousSpotListPage extends StatefulWidget {
  const DangerousSpotListPage({super.key});

  @override
  State<DangerousSpotListPage> createState() => _DangerousSpotListPageState();
}

class _DangerousSpotListPageState extends State<DangerousSpotListPage> {
  List spots = [];
  bool loading = true;
  String baseUrl = "";
  bool _hasError = false;
  String _errorMessage = "";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadSpots();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Could implement pagination here
    }
  }

  Future<void> loadSpots() async {
    setState(() {
      loading = true;
      _hasError = false;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      baseUrl = prefs.getString("url") ?? "";
      String lid = prefs.getString("lid") ?? "";

      if (baseUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = "Backend URL not configured";
          loading = false;
        });
        return;
      }

      var response = await http.post(
        Uri.parse("$baseUrl/user_view_dangerous_spot/"),
        body: {"lid": lid},
      );

      var jsonData = json.decode(response.body);

      if (jsonData["status"] == "ok") {
        setState(() {
          spots = jsonData["data"];
          loading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = "Failed to load spots: ${jsonData['message']}";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = "Connection error: $e";
        loading = false;
      });
    }
  }

  Future<void> _confirmDelete(int id, String placeName) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Delete Report",
          style: TextStyle(color: Color(0xFF880E4F)),
        ),
        content: Text(
          "Are you sure you want to delete the report for '$placeName'? This action cannot be undone.",
          style: TextStyle(color: Colors.grey[700]),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteSpot(id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSpot(int id) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String lid = prefs.getString("lid") ?? "";

      var response = await http.post(
        Uri.parse("$baseUrl/user_delete_dangerous_spot/"),
        body: {"lid": lid, "id": id.toString()},
      );

      var jsonData = json.decode(response.body);

      if (jsonData["status"] == "ok") {
        showSnackBar("Report deleted successfully!", isError: false);
        loadSpots();
      } else {
        showSnackBar("Error: ${jsonData['message']}");
      }
    } catch (e) {
      showSnackBar("Connection error: $e");
    }
  }

  void showSnackBar(String message, {bool isError = true}) {
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

  Widget _buildStatusChip(String status) {
    Color chipColor;
    Color textColor;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'verified':
        chipColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.verified_outlined;
        break;
      case 'pending':
        chipColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.pending_outlined;
        break;
      case 'rejected':
        chipColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        icon = Icons.cancel_outlined;
        break;
      default:
        chipColor = Colors.grey[100]!;
        textColor = Colors.grey[800]!;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
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
          "My Reports",
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
            onPressed: loadSpots,
            tooltip: "Refresh",
          ),
          IconButton(
            icon: const Icon(Icons.add_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDangerousSpotPage()),
              ).then((value) => loadSpots());
            },
            tooltip: "Add New Report",
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddDangerousSpotPage()),
          ).then((value) => loadSpots());
        },
        backgroundColor: Color(0xFFE91E63),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add_outlined),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
            ),
            const SizedBox(height: 16),
            Text(
              "Loading your reports...",
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
              onPressed: loadSpots,
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

    if (spots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              size: 72,
              color: Colors.pink[200],
            ),
            const SizedBox(height: 20),
            Text(
              "No reports yet",
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
                "Help keep others safe by reporting dangerous locations in your area",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddDangerousSpotPage()),
                ).then((value) => loadSpots());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE91E63),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text("Report Your First Spot"),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadSpots,
      color: Color(0xFFE91E63),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: spots.length,
        itemBuilder: (context, index) {
          var s = spots[index];
          return _buildSpotCard(s);
        },
      ),
    );
  }

  Widget _buildSpotCard(Map<String, dynamic> spot) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.pink[100]!, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Could add detail view navigation here
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image/Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.pink[50],
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            spot["place"] ?? "Unknown Location",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildStatusChip(spot["status"] ?? "Pending"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (spot["latitude"] != null && spot["longitude"] != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              "Lat: ${spot["latitude"]}, Lon: ${spot["longitude"]}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditDangerousSpotPage(data: spot),
                                ),
                              ).then((value) => loadSpots());
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFFE91E63),
                              side: BorderSide(color: Color(0xFFE91E63)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text("Edit"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmDelete(
                              spot["id"],
                              spot["place"] ?? "this report",
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text("Delete"),
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
}