import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewNearbyDangerousPointPage extends StatefulWidget {
  const ViewNearbyDangerousPointPage({super.key});

  @override
  State<ViewNearbyDangerousPointPage> createState() =>
      _ViewNearbyDangerousPointPageState();
}

class _ViewNearbyDangerousPointPageState
    extends State<ViewNearbyDangerousPointPage> {
  List<Map<String, dynamic>> dangerousSpots = [];
  bool _isLoading = true;
  String _baseUrl = "";

  @override
  void initState() {
    super.initState();
    fetchDangerousSpots();
  }

  Future<void> fetchDangerousSpots() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        print("❌ Missing URL or LID");
        setState(() => _isLoading = false);
        return;
      }

      String url = "$baseUrl/user_view_nearbyDangerosSpot/";
      print("🔗 Fetching dangerous spots from: $url");

      var response = await http.post(
        Uri.parse(url),
        body: {
          "lid": lid,
          "radius": "2", // km
        },
      );

      print("Response: ${response.body}");

      var jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 'ok') {
        setState(() {
          dangerousSpots = List<Map<String, dynamic>>.from(jsonData['data']);
          _baseUrl = baseUrl;
          _isLoading = false;
        });
      } else {
        print("⚠️ Error: ${jsonData['message']}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("❌ Exception: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> openMap(String lat, String lng) async {
    final Uri url = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng");

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        showSnackBar("Could not open map");
      }
    } catch (e) {
      showSnackBar("Error opening map: $e");
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Nearby Dangerous Spots",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? _buildLoadingState()
          : dangerousSpots.isEmpty
          ? _buildEmptyState()
          : _buildDangerousSpotList(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red[300]!),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Scanning for dangerous spots...",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.green.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No Dangerous Spots Nearby",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No reported dangerous spots within 2km radius",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchDangerousSpots,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Refresh"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerousSpotList() {
    return RefreshIndicator(
      onRefresh: fetchDangerousSpots,
      color: const Color(0xFFD32F2F),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: dangerousSpots.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final spot = dangerousSpots[index];
          return _buildDangerousSpotCard(spot);
        },
      ),
    );
  }

  Widget _buildDangerousSpotCard(Map<String, dynamic> spot) {
    double distance = double.tryParse(spot['distance']?.toString() ?? '0') ?? 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Danger Badge and Distance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "DANGEROUS AREA",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${distance.toStringAsFixed(1)} km",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Name
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.place_outlined,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    spot['place'] ?? "Unnamed Location",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Image
            if (spot['landmark'] != null && spot['landmark'].toString().isNotEmpty)
              Column(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        "$_baseUrl${spot['landmark']}",
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 1,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Unable to load image",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            // Coordinates Info
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Latitude",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          spot['latitude']?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Longitude",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          spot['longitude']?.toString() ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons
            SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () {
                  openMap(
                    spot['latitude'].toString(),
                    spot['longitude'].toString(),
                  );
                },
                icon: Icon(
                  Icons.map_outlined,
                  size: 18,
                  color: Colors.red,
                ),
                label: Text(
                  "View on Map",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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