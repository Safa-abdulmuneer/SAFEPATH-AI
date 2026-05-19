import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SendEmergencyRequestPage extends StatefulWidget {
  const SendEmergencyRequestPage({super.key});

  @override
  State<SendEmergencyRequestPage> createState() =>
      _SendEmergencyRequestPageState();
}

class _SendEmergencyRequestPageState extends State<SendEmergencyRequestPage> {
  TextEditingController requestCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isGettingLocation = false;
  String latitude = "";
  String longitude = "";
  String _locationError = "";

  Future<void> getLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = "";
    });

    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError = "Location permission denied. Please enable in settings.";
        });
        return;
      }

      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        latitude = pos.latitude.toStringAsFixed(6);
        longitude = pos.longitude.toStringAsFixed(6);
        _locationError = "";
      });
    } catch (e) {
      setState(() {
        _locationError = "Failed to get location: $e";
      });
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> sendRequest() async {
    if (requestCtrl.text.isEmpty) {
      showSnackBar("Please enter emergency message");
      return;
    }

    if (latitude.isEmpty || longitude.isEmpty) {
      showSnackBar("Please get your location first");
      return;
    }

    setState(() => _isLoading = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString("url") ?? "";
      String lid = prefs.getString("lid") ?? "";

      var response = await http.post(
        Uri.parse("$baseUrl/myapp/user_send_emergency_request/"),
        body: {
          "lid": lid,
          "request": requestCtrl.text,
          "latitude": latitude,
          "longitude": longitude,
        },
      );

      var jsonData = jsonDecode(response.body);

      if (jsonData["status"] == "ok") {
        showSnackBar("Emergency request sent successfully!", isError: false);
        // Clear form
        Future.delayed(const Duration(seconds: 2), () {
          requestCtrl.clear();
          setState(() {
            latitude = "";
            longitude = "";
          });
        });
      } else {
        showSnackBar("Failed to send request: ${jsonData['message']}");
      }
    } catch (e) {
      showSnackBar("Connection error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
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
          "Emergency Alert",
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning Header
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[400],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Use this only in case of emergency. Help will be dispatched immediately.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Message Input Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Emergency Message",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[50],
                        ),
                        child: TextField(
                          controller: requestCtrl,
                          maxLines: 5,
                          minLines: 4,
                          decoration: InputDecoration(
                            hintText: "Describe your situation clearly...\n\nExample: \"I need immediate help at...\"",
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[800],
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${requestCtrl.text.length} characters",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Location Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your Location",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Location Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isGettingLocation ? null : getLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.withOpacity(0.05),
                            foregroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                            ),
                            elevation: 0,
                          ),
                          child: _isGettingLocation
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text("Getting Location..."),
                            ],
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.location_on_outlined, size: 18),
                              SizedBox(width: 8),
                              Text("Get Current Location"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Location Display
                      if (latitude.isNotEmpty && longitude.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Location Acquired",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
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
                                        Text(
                                          latitude,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Longitude",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        Text(
                                          longitude,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[800],
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

                      // Error Message
                      if (_locationError.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 14,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _locationError,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
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
              const SizedBox(height: 24),

              // Emergency Send Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : sendRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emergency_outlined, size: 20),
                      SizedBox(width: 10),
                      Text("SEND EMERGENCY ALERT"),
                    ],
                  ),
                ),
              ),

              // Emergency Note
              Container(
                margin: const EdgeInsets.only(top: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Police and your emergency contacts will be notified immediately with your location and message. Stay on the line if possible.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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
    );
  }
}