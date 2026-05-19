import 'dart:async';
import 'dart:convert';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'sos_state.dart';

class SOSController {
  final SOSState state;

  SOSController(this.state);

  /* ===================== START / STOP ===================== */

  void start() {
    if (!state.toggleValue || !state.isUserOnHomePage) return;

    _startMotionDetection();
  }

  void stop() {
    state.motionSamplingTimer?.cancel();
    state.motionUpdateTimer?.cancel();
    state.accelerometerSub?.cancel();
    state.gyroscopeSub?.cancel();
    state.detectionResetTimer?.cancel();

    state.sensorBuffer.clear();

    state.voiceTriggerDetected = false;
    state.voiceEmotionDetected = false;
    state.phoneMotionDetected = false;
  }

  /* ===================== MOTION ===================== */

  void _startMotionDetection() {
    state.accelerometerSub =
        accelerometerEvents.listen((AccelerometerEvent e) {
          state.lastAccelerometer = e;
        });

    state.gyroscopeSub = gyroscopeEvents.listen((GyroscopeEvent e) {
      state.lastGyroscope = e;
    });

    state.motionSamplingTimer =
        Timer.periodic(const Duration(milliseconds: 33), (_) {
          _checkMotion();
        });
  }

  void _checkMotion() {
    if (state.lastAccelerometer == null ||
        state.lastGyroscope == null ||
        state.sosTriggered) return;

    final sample = {
      "ax": state.lastAccelerometer!.x,
      "ay": state.lastAccelerometer!.y,
      "az": state.lastAccelerometer!.z,
      "gx": state.lastGyroscope!.x,
      "gy": state.lastGyroscope!.y,
      "gz": state.lastGyroscope!.z,
    };

    state.sensorBuffer.add(sample);
    if (state.sensorBuffer.length > 10) {
      state.sensorBuffer.removeAt(0);
    }

    _sendMotionToBackend();
  }

  /* ===================== BACKEND ===================== */

  Future<void> _sendMotionToBackend() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String url = prefs.getString('url') ?? '';
      if (url.isEmpty) return;

      final res = await http.post(
        Uri.parse('$url/myapp/predict-motion/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"data": state.sensorBuffer}),
      );

      final data = jsonDecode(res.body);
      if (data['action'] == 'rapid_shake' && data['confidence'] > 0.8) {
        _onPhoneMotionDetected();
      }
    } catch (_) {}
  }

  /* ===================== MULTI FACTOR ===================== */

  void _onPhoneMotionDetected() {
    state.phoneMotionDetected = true;
    _checkMultiFactor();
    _startResetTimer();
  }

  void _checkMultiFactor() {
    int count = 0;
    if (state.voiceTriggerDetected) count++;
    if (state.voiceEmotionDetected) count++;
    if (state.phoneMotionDetected) count++;

    if (count >= 2 && !state.sosTriggered) {
      _triggerSOS();
    }
  }

  void _startResetTimer() {
    state.detectionResetTimer?.cancel();
    state.detectionResetTimer = Timer(const Duration(seconds: 30), () {
      state.voiceTriggerDetected = false;
      state.voiceEmotionDetected = false;
      state.phoneMotionDetected = false;
    });
  }

  /* ===================== SOS ===================== */

  void _triggerSOS() {
    state.sosTriggered = true;
    print("🚨 SOS TRIGGERED (MULTI-FACTOR)");
  }
  void checkMultiFactor() {
    int count = 0;

    if (state.voiceTriggerDetected) count++;
    if (state.voiceEmotionDetected) count++;
    if (state.phoneMotionDetected) count++;

    if (count >= 2 && !state.sosTriggered) {
      state.sosTriggered = true;
      print("🚨 SOS TRIGGERED (MULTI-FACTOR)");
    }
  }
  void onVoiceTriggerDetected() {
    state.voiceTriggerDetected = true;
    checkMultiFactor();
  }
  void onMotionDetected() {
    state.phoneMotionDetected = true;
    checkMultiFactor();
  }

}
