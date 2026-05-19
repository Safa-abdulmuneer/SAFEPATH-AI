import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddDangerousSpotPage extends StatefulWidget {
  const AddDangerousSpotPage({super.key});

  @override
  State<AddDangerousSpotPage> createState() => _AddDangerousSpotPageState();
}

class _AddDangerousSpotPageState extends State<AddDangerousSpotPage> {
  TextEditingController placeCtrl = TextEditingController();
  File? imageFile;
  String latitude = "";
  String longitude = "";
  String baseUrl = "";
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  String _locationError = "";

  @override
  void initState() {
    super.initState();
    getBase();
  }

  Future<void> getBase() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString("url") ?? "";
  }

  Future<void> pickLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = "";
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = "Location services are disabled. Please enable them.";
        });
        return;
      }

      // Check and request location permissions
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

      // Get current position
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitude = pos.latitude.toStringAsFixed(6);
        longitude = pos.longitude.toStringAsFixed(6);
      });

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Location acquired successfully!"),
          backgroundColor: Color(0xFFE91E63),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _locationError = "Error getting location: $e";
      });
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked != null) {
      setState(() => imageFile = File(picked.path));
    }
  }

  Future<void> submitSpot() async {
    if (placeCtrl.text.isEmpty) {
      showSnackBar("Please enter a place description");
      return;
    }

    if (latitude.isEmpty || longitude.isEmpty) {
      showSnackBar("Please get your current location first");
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String lid = prefs.getString("lid") ?? "";

      if (baseUrl.isEmpty) {
        showSnackBar("Backend URL missing");
        return;
      }

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/add_dangerous_spot/"),
      );

      request.fields["lid"] = lid;
      request.fields["place"] = placeCtrl.text;
      request.fields["latitude"] = latitude;
      request.fields["longitude"] = longitude;



      var response = await request.send();
      var data = await response.stream.bytesToString();
      var jsonData = json.decode(data);

      if (jsonData["status"] == "ok") {
        showSnackBar("Dangerous spot reported successfully!", isError: false);
        // Clear form and navigate back after delay
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      } else {
        showSnackBar("Error: ${jsonData['message']}");
      }
    } catch (e) {
      showSnackBar("Connection error: $e");
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Report Dangerous Spot",
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
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Report unsafe location",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF880E4F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Help keep others safe by reporting locations that feel dangerous or unsafe",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.pink[100]!, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Place Description Field
                      _buildTextField(
                        controller: placeCtrl,
                        label: "Place Description",
                        hint: "Describe the location in detail...",
                        icon: Icons.place_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Location Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Get Current Location",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF880E4F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _isGettingLocation ? null : pickLocation,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink[50],
                                foregroundColor: Color(0xFFE91E63),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.pink[200]!, width: 1.5),
                                ),
                                elevation: 0,
                              ),
                              icon: _isGettingLocation
                                  ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                                ),
                              )
                                  : Icon(Icons.location_on_outlined, size: 22),
                              label: _isGettingLocation
                                  ? Text("Getting location...")
                                  : Text("Get Current Location"),
                            ),
                          ),
                          if (_locationError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _locationError,
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          if (latitude.isNotEmpty && longitude.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.pink[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.pink[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Color(0xFFE91E63),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Location acquired:",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFFC2185B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Lat: $latitude\nLon: $longitude",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : submitSpot,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE91E63),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                            shadowColor: Colors.pink[200],
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.warning_amber_outlined, size: 22),
                              SizedBox(width: 10),
                              Text("Report Dangerous Spot"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info Note
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pink[50]!, Colors.purple[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pink[100]!, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xFFE91E63),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.security_outlined,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Privacy Note:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF880E4F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Your report will be anonymous and visible to other users. This helps create a safer community by warning others about potentially dangerous areas.",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF880E4F),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.pink[50]!,
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            minLines: maxLines == 1 ? 1 : 2,
            style: TextStyle(color: Colors.grey[800]),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], height: 1.4),
              prefixIcon: Icon(icon, size: 22, color: Color(0xFFE91E63)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.pink[200]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.pink[200]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE91E63), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 18,
                vertical: maxLines == 1 ? 16 : 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}