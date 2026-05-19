// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class ViewSafePointsPage extends StatefulWidget {
//   const ViewSafePointsPage({super.key});
//
//   @override
//   State<ViewSafePointsPage> createState() => _ViewSafePointsPageState();
// }
//
// class _ViewSafePointsPageState extends State<ViewSafePointsPage> {
//   List safepoints = [];
//   bool _isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchSafePoints();
//   }
//
//   Future<void> fetchSafePoints() async {
//     try {
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       String baseUrl = prefs.getString('url') ?? '';
//
//       if (baseUrl.isEmpty) {
//         print("❌ No URL found!");
//         setState(() => _isLoading = false);
//         return;
//       }
//
//       String url = "$baseUrl/user_view_safepoints/";
//       print("🔗 Fetching safe points from: $url");
//
//       var response = await http.post(Uri.parse(url));
//       print("Response: ${response.body}");
//
//       var jsonData = json.decode(response.body);
//
//       if (jsonData['status'] == 'ok') {
//         setState(() {
//           safepoints = jsonData['data'];
//           _isLoading = false;
//         });
//       } else {
//         print("⚠️ Error: ${jsonData['message']}");
//         setState(() => _isLoading = false);
//       }
//     } catch (e) {
//       print("❌ Exception: $e");
//       setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _openMap(String lat, String lng) async {
//     final Uri googleMapUrl = Uri.parse(
//       "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
//     );
//
//     try {
//       if (await canLaunchUrl(googleMapUrl)) {
//         await launchUrl(
//           googleMapUrl,
//           mode: LaunchMode.externalApplication,
//         );
//       } else {
//         showSnackBar("Could not open map");
//       }
//     } catch (e) {
//       showSnackBar("Error opening map: $e");
//     }
//   }
//
//   void showSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.redAccent,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Safe Points",
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//         iconTheme: const IconThemeData(color: Colors.black87),
//       ),
//       backgroundColor: Colors.white,
//       body: _isLoading
//           ? _buildLoadingState()
//           : safepoints.isEmpty
//           ? _buildEmptyState()
//           : _buildSafePointsList(),
//     );
//   }
//
//   Widget _buildLoadingState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           SizedBox(
//             width: 40,
//             height: 40,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.pink[300]!),
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             "Loading safe points...",
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.location_off_outlined,
//             size: 64,
//             color: Colors.grey.withOpacity(0.3),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             "No Safe Points Available",
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w600,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Check back later for updated safe locations",
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[500],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSafePointsList() {
//     return RefreshIndicator(
//       onRefresh: fetchSafePoints,
//       color: const Color(0xFF4CAF50),
//       child: ListView.separated(
//         padding: const EdgeInsets.all(20),
//         itemCount: safepoints.length,
//         separatorBuilder: (_, __) => const SizedBox(height: 16),
//         itemBuilder: (context, index) {
//           var item = safepoints[index];
//           return _buildSafePointCard(item);
//         },
//       ),
//     );
//   }
//
//   Widget _buildSafePointCard(Map<String, dynamic> item) {
//     return Card(
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: Colors.pink.withOpacity(0.2)),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header with Safe Point Badge
//             Container(
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 12,
//                 vertical: 6,
//               ),
//               decoration: BoxDecoration(
//                 color: Colors.pink.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Icon(
//                     Icons.shield_outlined,
//                     size: 14,
//                     color: Colors.pink,
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     "SAFE POINT",
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.pink,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//
//             // Place Name
//             Row(
//               children: [
//                 Container(
//                   width: 40,
//                   height: 40,
//                   decoration: BoxDecoration(
//                     color: Colors.pink.withOpacity(0.1),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     Icons.place_outlined,
//                     color: Colors.pink,
//                     size: 18,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     item['place'],
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//
//
//             // Coordinates
//             Row(
//               children: [
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[50],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Latitude",
//                           style: TextStyle(
//                             fontSize: 11,
//                             color: Colors.grey[500],
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           item['latitude'],
//                           style: TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Container(
//                     padding: const EdgeInsets.all(10),
//                     decoration: BoxDecoration(
//                       color: Colors.grey[50],
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Longitude",
//                           style: TextStyle(
//                             fontSize: 11,
//                             color: Colors.grey[500],
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           item['longitude'],
//                           style: TextStyle(
//                             fontSize: 13,
//                             fontWeight: FontWeight.w500,
//                             color: Colors.grey[800],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//
//             // Action Button
//             SizedBox(
//               height: 44,
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   _openMap(item['latitude'], item['longitude']);
//                 },
//                 icon: const Icon(
//                   Icons.map_outlined,
//                   size: 18,
//                   color: Colors.white,
//                 ),
//                 label: const Text(
//                   "View on Map",
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     color: Colors.white,
//                   ),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.pink,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewSafePointsPage extends StatefulWidget {
  const ViewSafePointsPage({super.key});

  @override
  State<ViewSafePointsPage> createState() => _ViewSafePointsPageState();
}

class _ViewSafePointsPageState extends State<ViewSafePointsPage> {
  List safepoints = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchSafePoints();
  }

  Future<void> fetchSafePoints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';

      if (baseUrl.isEmpty) {
        setState(() {
          _errorMessage = "Server URL not configured";
          _isLoading = false;
        });
        return;
      }

      String url = "$baseUrl/user_view_safepoints/";
      print("🔗 Fetching safe points from: $url");

      var response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ).timeout(const Duration(seconds: 10));

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);

        if (jsonData['status'] == 'ok') {
          setState(() {
            safepoints = jsonData['data'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = jsonData['message'] ?? "Failed to load safe points";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Server error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Exception: $e");
      setState(() {
        _errorMessage = "Network error. Please check your connection.";
        _isLoading = false;
      });
    }
  }

  // FIXED: Map opening function
  Future<void> _openMap(String lat, String lng) async {
    try {
      // Method 1: Google Maps URL (most reliable)
      final Uri googleMapsUrl = Uri.parse(
          "https://www.google.com/maps/search/?api=1&query=$lat,$lng"
      );

      // Method 2: Geo URI (opens in any map app)
      final Uri geoUri = Uri.parse("geo:$lat,$lng");

      // Method 3: Google Maps app intent (for Android)
      final Uri googleMapsAppUri = Uri.parse(
          "google.navigation:q=$lat,$lng"
      );

      print("🌍 Opening map at: $lat, $lng");

      // Try Google Maps web URL first
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(
          googleMapsUrl,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      // Then try geo URI
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      // Finally try Google Maps app
      if (await canLaunchUrl(googleMapsAppUri)) {
        await launchUrl(
          googleMapsAppUri,
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      // If all fail, show error
      showSnackBar("No map application found");

    } catch (e) {
      print("❌ Map error: $e");
      showSnackBar("Could not open map: $e");
    }
  }

  void showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Safe Points",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.pink,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: fetchSafePoints,
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
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (safepoints.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSafePointsList();
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
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Loading safe points...",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: fetchSafePoints,
              icon: const Icon(Icons.refresh_outlined),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
            Icons.location_off_outlined,
            size: 64,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "No Safe Points Available",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Check back later for updated safe locations",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchSafePoints,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text("Refresh"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafePointsList() {
    return RefreshIndicator(
      onRefresh: fetchSafePoints,
      color: Colors.pink,
      backgroundColor: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: safepoints.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          var item = safepoints[index];
          return _buildSafePointCard(item);
        },
      ),
    );
  }

  Widget _buildSafePointCard(Map<String, dynamic> item) {
    String latitude = item['latitude']?.toString() ?? '0';
    String longitude = item['longitude']?.toString() ?? '0';
    String place = item['place']?.toString() ?? 'Unknown Location';

    return Card(
      elevation: 2,
      shadowColor: Colors.pink.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Safe Point Badge
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: Colors.pink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "SAFE POINT",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.pink,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.verified,
                  size: 20,
                  color: Colors.pink[300],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Place Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.place_outlined,
                    color: Colors.pink,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Safe Location",
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
            const SizedBox(height: 16),

            // Coordinates
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Latitude",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          latitude,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.grey[300],
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Longitude",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          longitude,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _openMap(latitude, longitude);
                    },
                    icon: Icon(
                      Icons.map_outlined,
                      size: 18,
                      color: Colors.pink,
                    ),
                    label: Text(
                      "View Map",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.pink,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.pink),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _openMap(latitude, longitude);
                    },
                    icon: const Icon(
                      Icons.navigation_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Navigate",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}