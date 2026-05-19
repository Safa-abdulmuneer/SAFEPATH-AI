import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditDangerousSpotPage extends StatefulWidget {
  final Map data;

  const EditDangerousSpotPage({super.key, required this.data});

  @override
  State<EditDangerousSpotPage> createState() => _EditDangerousSpotPageState();
}

class _EditDangerousSpotPageState extends State<EditDangerousSpotPage> {
  TextEditingController placeCtrl = TextEditingController();
  File? newImage;
  String latitude = "";
  String longitude = "";
  String baseUrl = "";
  bool _isSubmitting = false;
  bool _isGettingLocation = false;
  String _locationError = "";
  String _currentImageUrl = "";

  @override
  void initState() {
    super.initState();
    setup();
  }

  Future<void> setup() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    baseUrl = prefs.getString("url") ?? "";

    placeCtrl.text = widget.data["place"] ?? "";
    latitude = widget.data["latitude"] ?? "";
    longitude = widget.data["longitude"] ?? "";
    _currentImageUrl = widget.data["photo"] ?? "";

    setState(() {});
  }

  Future<void> pickLocation() async {
    setState(() {
      _isGettingLocation = true;
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
          _locationError = "Location permissions are permanently denied";
        });
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitude = pos.latitude.toStringAsFixed(6);
        longitude = pos.longitude.toStringAsFixed(6);
      });

      showSnackBar("Location updated successfully!", isError: false);
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
      setState(() => newImage = File(picked.path));
    }
  }

  Future<void> updateSpot() async {
    if (placeCtrl.text.isEmpty) {
      showSnackBar("Please enter a place description");
      return;
    }

    if (latitude.isEmpty || longitude.isEmpty) {
      showSnackBar("Please update location coordinates");
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
        Uri.parse("$baseUrl/user_update_dangerous_spot/"),
      );

      request.fields["lid"] = lid;
      request.fields["id"] = widget.data["id"].toString();
      request.fields["place"] = placeCtrl.text;
      request.fields["latitude"] = latitude;
      request.fields["longitude"] = longitude;

      if (newImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          "photo",
          newImage!.path,
        ));
      }

      var response = await request.send();
      var data = await response.stream.bytesToString();
      var jsonData = json.decode(data);

      if (jsonData["status"] == "ok") {
        showSnackBar("Spot updated successfully!", isError: false);
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
          "Edit Dangerous Spot",
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
          if (widget.data["id"] != null)
            IconButton(
              icon: Icon(Icons.delete_outline),
              onPressed: () => _showDeleteConfirmation(),
              tooltip: "Delete spot",
            ),
        ],
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
                      "Update spot details",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF880E4F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Modify the location information or update the photo",
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
                            "Update Location",
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
                                  : Text("Update Current Location"),
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
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.pink[200]!),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_pin,
                                  color: Color(0xFFE91E63),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Current Coordinates:",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFFC2185B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Latitude: $latitude\nLongitude: $longitude",
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

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : updateSpot,
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
                              Icon(Icons.save_outlined, size: 22),
                              SizedBox(width: 10),
                              Text("Save Changes"),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Warning Note
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
                        Icons.warning_amber_outlined,
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
                            "Important:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF880E4F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Updating this spot will modify its details for all users. Ensure the information is accurate and helpful for community safety.",
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

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Dangerous Spot",
          style: TextStyle(color: Color(0xFF880E4F)),
        ),
        content: Text(
          "Are you sure you want to delete this dangerous spot? This action cannot be undone.",
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
            onPressed: () => _deleteSpot(),
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

  Future<void> _deleteSpot() async {
    Navigator.pop(context); // Close dialog

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String lid = prefs.getString("lid") ?? "";

      var response = await http.post(
        Uri.parse("$baseUrl/myapp/user_delete_dangerous_spot/"),
        body: {
          'lid': lid,
          'id': widget.data["id"].toString(),
        },
      );

      var jsonData = json.decode(response.body);

      if (jsonData["status"] == "ok") {
        showSnackBar("Spot deleted successfully!", isError: false);
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      } else {
        showSnackBar("Error: ${jsonData['message']}");
      }
    } catch (e) {
      showSnackBar("Connection error: $e");
    }
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