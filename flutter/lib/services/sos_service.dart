import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SOSService {
  // Add latitude and longitude parameters
  static Future<void> triggerSOS({
    required List<dynamic> phone,
    required double latitude,    // Add this
    required double longitude,   // Add this
  }) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        print('❌ No backend URL found');
        return;
      }

      String url = "$baseUrl/sos_alert/";

      // Add latitude and longitude to the data
      Map<String, String> data = {
        'lid': lid,
        'phone_numbers': json.encode(phone),
        'timestamp': DateTime.now().toIso8601String(),
        'latitude': latitude.toString(),    // Add this
        'longitude': longitude.toString(),  // Add this
      };

      print("📤 Sending SOS with location: $latitude, $longitude");
      print("📤 Data: $data");

      var response = await http.post(
        Uri.parse(url),
        body: data,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ SOS alert sent successfully');
      } else {
        print('❌ Failed to send SOS: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending SOS: $e');
    }
  }
}