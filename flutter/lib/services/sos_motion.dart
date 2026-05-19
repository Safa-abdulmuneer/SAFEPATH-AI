import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:shecare/services/sos_state.dart';


class SOSMotion {
  final SOSState state;

  SOSMotion(this.state);

  void startMotionDetection() {
    if (!state.toggleValue || !state.isUserOnHomePage) return;

    state.accelerometerSub =
        accelerometerEvents.listen((event) {
          state.lastAccelerometer = event;
        });

    state.gyroscopeSub =
        gyroscopeEvents.listen((event) {
          state.lastGyroscope = event;
        });

    state.motionSamplingTimer =
        Timer.periodic(const Duration(milliseconds: 33), (_) {
          checkMotionForSOS();
        });

    state.motionUpdateTimer =
        Timer.periodic(const Duration(seconds: 3), (_) {
          getLastCapturedMotion();
        });
  }

  void checkMotionForSOS() {
    if (state.lastAccelerometer == null ||
        state.lastGyroscope == null ||
        state.sosTriggered ||
        !state.toggleValue ||
        !state.isUserOnHomePage) return;

    Map<String, double> sample = {
      "ax": state.lastAccelerometer!.x,
      "ay": state.lastAccelerometer!.y,
      "az": state.lastAccelerometer!.z,
      "gx": state.lastGyroscope!.x,
      "gy": state.lastGyroscope!.y,
      "gz": state.lastGyroscope!.z,
    };

    addToSensorBuffer(sample);

    if (isSignificantMotion(sample)) {
      sendMotionToBackend(getSensorBuffer());
    }
  }

  void addToSensorBuffer(Map<String, double> sample) {
    state.sensorBuffer.add(sample);
    if (state.sensorBuffer.length > 10) {
      state.sensorBuffer.removeAt(0);
    }
  }

  List<Map<String, double>> getSensorBuffer() {
    return List.from(state.sensorBuffer);
  }

  bool isSignificantMotion(Map<String, double> sample) {
    double accMag = sqrt(
      sample['ax']! * sample['ax']! +
          sample['ay']! * sample['ay']! +
          sample['az']! * sample['az']!,
    );

    double gyroMag = sqrt(
      sample['gx']! * sample['gx']! +
          sample['gy']! * sample['gy']! +
          sample['gz']! * sample['gz']!,
    );

    return accMag > 20 || gyroMag > 5;
  }

  Future<void> sendMotionToBackend(
      List<Map<String, double>> samples) async {
    try {
      SharedPreferences sh =
      await SharedPreferences.getInstance();
      String urls = sh.getString('url') ?? '';
      if (urls.isEmpty) return;

      var res = await http.post(
        Uri.parse('$urls/myapp/predict-motion/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"data": samples}),
      );

      if (res.statusCode == 200) {
        var result = jsonDecode(res.body);
        if (result['confidence'] > 0.8) {
          setPhoneMotionDetected();
        }
      }
    } catch (e) {
      print("Motion error: $e");
    }
  }

  void setPhoneMotionDetected() {
    if (!state.toggleValue || !state.isUserOnHomePage) return;
    state.phoneMotionDetected = true;
  }

  Future<void> getLastCapturedMotion() async {}
}

