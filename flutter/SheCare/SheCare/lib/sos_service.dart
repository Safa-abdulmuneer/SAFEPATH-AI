import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SOSService {
  static bool _sending = false;

  // ✅ Trigger SOS with latitude and longitude from home page
  static Future<void> triggerSOS({
    required List<dynamic> phone,
    required double latitude,    // Add this parameter
    required double longitude,   // Add this parameter
  }) async {
    if (_sending) return;
    _sending = true;

    try {
      // Get user data from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        Fluttertoast.showToast(msg: "❌ Server URL not configured");
        _sending = false;
        return;
      }

      // Prepare data with location from home page
      Map<String, String> data = {
        'lid': lid,
        'phone_numbers': json.encode(phone),
        'latitude': latitude.toString(),      // Use passed latitude
        'longitude': longitude.toString(),    // Use passed longitude
        'timestamp': DateTime.now().toIso8601String(),
      };

      print("📤 Sending SOS to backend:");
      print("📍 Location from home page: $latitude, $longitude");
      print("📱 Phone numbers: $phone");
      print("🔗 URL: $baseUrl/sos_alert/");

      // Send to backend
      var response = await http.post(
        Uri.parse('$baseUrl/sos_alert/'),
        body: data,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        print("✅ SOS sent successfully: $responseData");
        Fluttertoast.showToast(msg: "✅ SOS alert sent to server!");
      } else {
        print("❌ Server error: ${response.statusCode}");
        print("❌ Response: ${response.body}");
        Fluttertoast.showToast(msg: "❌ Failed to send SOS");
      }

    } catch (e) {
      print("❌ SOS Error: $e");
      Fluttertoast.showToast(msg: "❌ Error: $e");
    }

    _sending = false;
  }
}