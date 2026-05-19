import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NearbyUsersPage extends StatefulWidget {
  const NearbyUsersPage({super.key});

  @override
  State<NearbyUsersPage> createState() => _NearbyUsersPageState();
}

class _NearbyUsersPageState extends State<NearbyUsersPage> {
  List users = [];
  bool loading = true;
  bool _updatingLocation = false;
  String baseUrl = "";
  String _locationError = "";
  String _networkError = "";
  double _currentRadius = 2.0; // Default radius in KM
  final ScrollController _scrollController = ScrollController();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    initialize();
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

  Future<void> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString('url') ?? "";
    await refreshNearby();
  }

  // Update user location
  Future<void> updateUserLocation() async {
    setState(() {
      _updatingLocation = true;
      _locationError = "";
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = "Location services are disabled. Please enable them.";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = "Location permissions are denied";
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = "Location permissions are permanently denied. Please enable them in app settings.";
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String lid = prefs.getString('lid') ?? "";

      if (lid.isEmpty) {
        setState(() {
          _locationError = "User not logged in";
        });
        return;
      }

      await http.post(
        Uri.parse("$baseUrl/myapp/update_location/"),
        body: {
          "lid": lid,
          "latitude": position.latitude.toString(),
          "longitude": position.longitude.toString(),
        },
      );

    } catch (e) {
      setState(() {
        _locationError = "Error updating location: $e";
      });
    } finally {
      setState(() {
        _updatingLocation = false;
      });
    }
  }

  // Fetch nearby users
  Future<void> loadNearbyUsers() async {
    setState(() {
      loading = true;
      _networkError = "";
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String lid = prefs.getString('lid') ?? "";

      if (lid.isEmpty) {
        setState(() {
          _networkError = "User not logged in";
          loading = false;
        });
        return;
      }

      var response = await http.post(
        Uri.parse("$baseUrl/view_nearby_users/"),
        body: {
          "lid": lid,
          "radius": _currentRadius.toStringAsFixed(1),
        },
      );

      var jsonData = json.decode(response.body);

      if (jsonData["status"] == "ok") {
        setState(() {
          users = jsonData["users"];
          loading = false;
        });
      } else {
        setState(() {
          _networkError = "Failed to load users: ${jsonData['message']}";
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _networkError = "Connection error: $e";
        loading = false;
      });
    }
  }

  // Pull-to-refresh
  Future<void> refreshNearby() async {
    await updateUserLocation();
    await loadNearbyUsers();
  }

  Widget _buildDistanceIndicator(double distance) {
    Color color;
    IconData icon;
    String label;

    if (distance < 0.5) {
      color = Colors.green[600]!;
      icon = Icons.near_me;
      label = "Very Close";
    } else if (distance < 1.0) {
      color = Colors.blue[600]!;
      icon = Icons.location_on;
      label = "Close";
    } else if (distance < 2.0) {
      color = Colors.orange[600]!;
      icon = Icons.location_pin;
      label = "Nearby";
    } else {
      color = Colors.grey[600]!;
      icon = Icons.location_off_sharp;
      label = "Within ${distance.toStringAsFixed(1)} km";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    double distance = double.tryParse(user["distance_km"]?.toString() ?? "0") ?? 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.pink[100]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.pink[200]!, width: 2),
              ),
              child: ClipOval(
                child: user["photo"] != null && user["photo"].isNotEmpty
                    ? Image.network(
                  "$baseUrl${user['photo']}",
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.pink[50],
                      child: Icon(
                        Icons.person_outline,
                        size: 32,
                        color: Color(0xFFE91E63),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.pink[50],
                  child: Icon(
                    Icons.person_outline,
                    size: 32,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // User Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          user["name"] ?? "Unknown User",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildDistanceIndicator(distance),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (user["phone"] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user["phone"].toString(),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  if (user["email"] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            user["email"].toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Action Buttons
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: OutlinedButton.icon(
                  //         onPressed: () {
                  //           // Call functionality
                  //           if (user["phone"] != null) {
                  //             // Implement call functionality
                  //           }
                  //         },
                  //         style: OutlinedButton.styleFrom(
                  //           foregroundColor: Color(0xFFE91E63),
                  //           side: BorderSide(color: Color(0xFFE91E63)),
                  //           shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(8),
                  //           ),
                  //           padding: const EdgeInsets.symmetric(vertical: 6),
                  //         ),
                  //         icon: const Icon(Icons.call_outlined, size: 16),
                  //         label: const Text("Call"),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 8),
                  //     Expanded(
                  //       child: OutlinedButton.icon(
                  //         onPressed: () {
                  //           // Message functionality
                  //         },
                  //         style: OutlinedButton.styleFrom(
                  //           foregroundColor: Colors.blue[600],
                  //           side: BorderSide(color: Colors.blue[600]!),
                  //           shape: RoundedRectangleBorder(
                  //             borderRadius: BorderRadius.circular(8),
                  //           ),
                  //           padding: const EdgeInsets.symmetric(vertical: 6),
                  //         ),
                  //         icon: const Icon(Icons.message_outlined, size: 16),
                  //         label: const Text("Message"),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentLocationCard() {
    if (_currentPosition == null) return const SizedBox();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.pink[100]!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.my_location_outlined,
                  color: Color(0xFFE91E63),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Your Current Location",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF880E4F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                    "Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, "
                        "Lon: ${_currentPosition!.longitude.toStringAsFixed(6)}",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Radius Slider
            Row(
              children: [
                Icon(
                  Icons.radar_outlined,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Search Radius:",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            "${_currentRadius.toStringAsFixed(1)} km",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE91E63),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _currentRadius,
                        min: 0.5,
                        max: 10.0,
                        divisions: 19,
                        label: _currentRadius.toStringAsFixed(1),
                        activeColor: Color(0xFFE91E63),
                        inactiveColor: Colors.pink[100],
                        onChanged: (value) {
                          setState(() {
                            _currentRadius = value;
                          });
                        },
                        onChangeEnd: (value) async {
                          await loadNearbyUsers();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Nearby Users",
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
            onPressed: refreshNearby,
            tooltip: "Refresh",
          ),
          IconButton(
            icon: const Icon(Icons.my_location_outlined),
            onPressed: updateUserLocation,
            tooltip: "Update Location",
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading && users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
            ),
            const SizedBox(height: 16),
            if (_updatingLocation)
              Text(
                "Updating your location...",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              )
            else
              Text(
                "Finding nearby users...",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshNearby,
      color: Color(0xFFE91E63),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          // Location Error Display
          if (_locationError.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _locationError,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Current Location Card
          _buildCurrentLocationCard(),

          // Network Error Display
          if (_networkError.isNotEmpty && users.isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.wifi_off_outlined,
                        color: Colors.orange[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _networkError,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: loadNearbyUsers,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[100],
                      foregroundColor: Colors.orange[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    icon: const Icon(Icons.refresh_outlined, size: 16),
                    label: const Text("Try Again"),
                  ),
                ],
              ),
            ),

          // Results Header
          if (users.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Nearby Users (${users.length})",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF880E4F),
                    ),
                  ),
                  if (loading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                      ),
                    )
                  else
                    Text(
                      "Within ${_currentRadius.toStringAsFixed(1)} km",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),

          // Users List
          if (users.isNotEmpty)
            ...users.asMap().entries.map((entry) {
              return _buildUserCard(entry.value, entry.key);
            }),

          // Empty State
          if (users.isEmpty && !loading && _networkError.isEmpty && _locationError.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 72,
                    color: Colors.pink[200],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No users nearby",
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
                      "No other users found within ${_currentRadius.toStringAsFixed(1)} km radius. Try increasing the search radius.",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentRadius = 5.0;
                      });
                      loadNearbyUsers();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE91E63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.search_outlined),
                    label: const Text("Increase Search Radius"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}