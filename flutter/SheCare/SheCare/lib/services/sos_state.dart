import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class SOSState {
  bool toggleValue = false;
  bool toggleLoaded = false;
  bool sosTriggered = false;
  bool isListening = false;
  bool isRecording = false;
  bool isMicButtonPressed = false;
  Timer? detectionResetTimer;


  // speech
  final SpeechToText speech = SpeechToText();
  bool voiceTriggerDetected = false;
  bool voiceEmotionDetected = false;

  // motion
  AccelerometerEvent? lastAccelerometer;
  GyroscopeEvent? lastGyroscope;
  StreamSubscription? accelerometerSub;
  StreamSubscription? gyroscopeSub;
  Timer? motionSamplingTimer;
  Timer? motionUpdateTimer;
  bool phoneMotionDetected = false;

  // audio
  final FlutterSoundRecorder audioRecorder = FlutterSoundRecorder();
  String? currentAudioPath;

  // danger zone
  FlutterLocalNotificationsPlugin notifications =
  FlutterLocalNotificationsPlugin();
  Set<String> activeDangerZones = {};
  Map<String, int> zoneNotificationCount = {};
  Map<String, DateTime> lastZoneNotificationTime = {};

  // buffers
  List<Map<String, double>> sensorBuffer = [];

  bool isUserOnHomePage = true;
}
