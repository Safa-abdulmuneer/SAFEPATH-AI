import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SafetyPredictionPage extends StatefulWidget {
  const SafetyPredictionPage({super.key});

  @override
  State<SafetyPredictionPage> createState() => _SafetyPredictionPageState();
}

class _SafetyPredictionPageState extends State<SafetyPredictionPage> {
  bool _isLoading = false;
  bool _isLoadingOptions = true;
  Map<String, dynamic>? predictionResult;
  String? errorMessage;
  String? lati="";
  String? logi="";

  bool _isGettingLocation = false;
  String _locationError = "";



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
        print("Locc  ");
        print(pos.latitude);
        print(pos.longitude);
        lati = pos.latitude.toStringAsFixed(6);
        logi = pos.longitude.toStringAsFixed(6);
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



  // Form controllers
  final _formKey = GlobalKey<FormState>();


  @override
  void initState() {
    super.initState();
    pickLocation();
  }

  Future<void> predictSafety() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      predictionResult = null;
      errorMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';

      if (baseUrl.isEmpty) {
        throw Exception('Server URL not configured');
      }

      final Map<String, dynamic> requestData = {
        'lati': lati,
        'logi': logi,
      };

      print("📤 Sending prediction request: $requestData");

      final response = await http.post(
        Uri.parse('$baseUrl/predict-safety/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      ).timeout(const Duration(seconds: 10));

      final jsonData = json.decode(response.body);

      if (jsonData['status'] == 'success') {
        setState(() {
          predictionResult = jsonData;
          _isLoading = false;
        });
        print("✅ Prediction: ${jsonData['prediction']}");
      } else {
        throw Exception(jsonData['message']);
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getSafetyColor(String prediction) {
    if (prediction.toLowerCase() == 'safe') return Colors.green;
    if (prediction.toLowerCase() == 'unsafe') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Safety Prediction',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE91E63),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.pink[50]!, Colors.white],
          ),
        ),
        child: errorMessage != null
            ? _buildErrorState()
            : _buildPredictionForm(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
          ),
          SizedBox(height: 16),
          Text('Loading model data...'),
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
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

          ],
        ),
      ),
    );
  }

  Widget _buildPredictionForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.pink[100]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.pink[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.security_outlined,
                      size: 40,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Location Safety Predictor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Message : ' + _locationError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Latitude : ' + lati!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Longitude : ' + logi!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Prediction Form
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [


                    // Predict Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : predictSafety,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE91E63),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                            : const Text(
                          'Predict Safety',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Prediction Result
          if (predictionResult != null) _buildResultCard(),
        ],
      ),
    );
  }


  Widget _buildResultCard() {
    String prediction = predictionResult!['prediction'];
    double confidence = predictionResult!['confidence'] * 100;
    Color safetyColor = _getSafetyColor(prediction);
    Map<String, dynamic> probabilities = predictionResult!['probabilities'];
    Map<String, dynamic> input_features = predictionResult!['input_features'];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              safetyColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Text(
              'Prediction Result',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: safetyColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: safetyColor),
              ),
              child: Text(
                prediction.toUpperCase(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: safetyColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Confidence: ${confidence.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            const Text(
              'Prediction based on features',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...input_features.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: Text(
                        entry.value,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
            const Text(
              'Probability Distribution',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...probabilities.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: entry.value,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getSafetyColor(entry.key),
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${(entry.value * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 11),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}