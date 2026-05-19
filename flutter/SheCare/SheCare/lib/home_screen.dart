import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shecare/UserDangerousSpot.dart';
import 'package:shecare/change_password.dart';
import 'package:shecare/chatBot.dart';
import 'package:shecare/emergency_number.dart';
import 'package:shecare/falseAlarmPage.dart';
import 'package:shecare/login.dart';
import 'package:shecare/safety_prediction_page.dart';
import 'package:shecare/sendComplaint.dart';
import 'package:shecare/sendRequest.dart';
import 'package:shecare/sos_history_page.dart';
import 'package:shecare/sos_service.dart';
import 'package:http/http.dart' as http;
import 'package:shecare/viewAllIdea.dart';
import 'package:shecare/viewCompalintReply.dart';
import 'package:shecare/viewNearbyDangerousSpots.dart';
import 'package:shecare/viewNearbyUser.dart';
import 'package:shecare/viewProfile.dart';
import 'package:shecare/viewSafePoints.dart';
import 'package:shecare/view_journey_own.dart';
import 'package:shecare/view_received_requests_page.dart';
import 'package:shecare/view_sent_requests_page.dart';
import 'package:telephony/telephony.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart'; // Make sure this is added
import 'ViewAllJourneys.dart';
import 'add_idea_page.dart';
import 'add_journey_details.dart';
import 'emergency_contacts_page.dart';
import 'my_credict_home.dart';

class UserHome extends StatefulWidget {
  const UserHome({Key? key}) : super(key: key);

  static const String id = 'HomeScreen';

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int selectedIndex = 0;
  List<dynamic> phn = [];
  List userData = [];

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  Timer? _continuousCheckTimer;
  Set<String> _activeDangerZones = {};

  // Voice detection
  bool _isListening = false;

  // Audio recording and sending
  bool _isRecording = false;
  String? _currentAudioPath;
  Timer? _recordingTimer;
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final int _recordingInterval = 30;

  // SOS trigger flag
  bool _sosTriggered = false;
  bool isMicButtonPressed = false;
  Timer? _sosCooldownTimer;

  // MOTION DETECTION VARIABLES
  AccelerometerEvent? _lastAccelerometer;
  GyroscopeEvent? _lastGyroscope;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  Timer? _motionSamplingTimer;
  final int _samplingRate = 33;

  // Motion detection state
  String _currentMotion = "monitoring";
  bool _motionDetectionActive = true;

  // SHAKE DETECTION VARIABLES
  double _shakeThreshold = 30.0;
  int _shakeCount = 0;
  DateTime? _lastShakeTime;
  final int _shakesNeeded = 3;
  final Duration _shakeTimeout = Duration(seconds: 2);

  // Previous accelerometer values
  double _prevAx = 0.0;
  double _prevAy = 0.0;
  double _prevAz = 0.0;

  // Buffer for smoothing
  List<double> _accelBuffer = [];
  final int _bufferSize = 5;

  // MULTI-FACTOR DETECTION VARIABLES
  bool _voiceTriggerDetected = false;
  bool _voiceEmotionDetected = false;
  bool _phoneMotionDetected = false;
  Timer? _detectionResetTimer;

  // VOLUME BUTTON VARIABLES
  int _volumeButtonPressCount = 0;
  Timer? _volumeButtonTimer;
  final int _requiredVolumePresses = 3;
  final Duration _volumePressTimeout = const Duration(seconds: 2);
  static const platform = MethodChannel('volume.channel');

  // TEXT-TO-SPEECH VARIABLES FOR DANGER SPOT VOICE ALERT
  FlutterTts flutterTts = FlutterTts();
  bool _isSpeaking = false;
  DateTime? _lastVoiceAlertTime;
  final Duration _voiceAlertCooldown = Duration(seconds: 30);
  Set<String> _announcedDangerZones = {};

  // Flag to track if initial check has been done
  bool _initialCheckDone = false;

  // LOCATION VARIABLES
  double _currentLat = 0.0;
  double _currentLng = 0.0;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _initializeTextToSpeech();


    // Load saved location from SharedPreferences
    _loadSavedLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      startSOSFeatures();
      _checkDangerSpotsOnLoad();
    });
  }

  // Load saved location from SharedPreferences
  Future<void> _loadSavedLocation() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? lat = prefs.getString('lat');
      String? lon = prefs.getString('lon');

      if (lat != null && lon != null && lat.isNotEmpty && lon.isNotEmpty) {
        setState(() {
          _currentLat = double.parse(lat);
          _currentLng = double.parse(lon);
        });
        print("📍 Loaded location from SharedPreferences: $_currentLat, $_currentLng");
      } else {
        print("📍 No saved location found, getting fresh location...");
        _getCurrentLocation();
      }
    } catch (e) {
      print("❌ Error loading saved location: $e");
      _getCurrentLocation();
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(
          msg: "Please enable location services",
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(
            msg: "Location permission denied",
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
          msg: "Location permissions permanently denied",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
      });

      // Save to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('lat', _currentLat.toString());
      await prefs.setString('lon', _currentLng.toString());

      print("📍 Fresh location fetched: $_currentLat, $_currentLng");

      // Update location on server
      _updateLocationOnServer();

    } catch (e) {
      print("❌ Error getting location: $e");
      Fluttertoast.showToast(
        msg: "Error getting location",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Update location on server
  Future<void> _updateLocationOnServer() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        return;
      }

      final urls = Uri.parse('$baseUrl/updatelocation/');
      final response = await http.post(urls, body: {
        'lid': lid,
        'lat': _currentLat.toString(),
        'lon': _currentLng.toString(),
      });

      if (response.statusCode == 200) {
        print("✅ Location updated on server");
      } else {
        print("❌ Failed to update location on server");
      }
    } catch (e) {
      print("❌ Error updating location on server: $e");
    }
  }

  // Start periodic location updates
  void _startLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      _getCurrentLocation();
    });
  }

  Future<void> _checkDangerSpotsOnLoad() async {
    print("🚨 [AUTO CHECK] Checking for dangerous spots on home page load...");

    await Future.delayed(Duration(seconds: 1));

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        print("❌ [AUTO CHECK] Missing baseUrl or lid");
        return;
      }

      String url = "$baseUrl/user_view_nearbyDangerosSpot/";
      var response = await http.post(
        Uri.parse(url),
        body: {'lid': lid, 'radius': '2'},
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);

        if (jsonData['status'] == 'ok' && jsonData.containsKey('data')) {
          var spots = jsonData['data'];
          print("✅ [AUTO CHECK] Found ${spots.length} spots");

          List<Map<String, dynamic>> dangerZones = [];

          for (var spot in spots) {
            String spotId = spot['id'].toString();
            double distance = double.tryParse(spot['distance'].toString()) ?? 999.0;
            String placeName = spot['place'] ?? 'Unknown location';

            if (distance <= 2.0) {
              dangerZones.add({
                'id': spotId,
                'name': placeName,
                'distance': distance,
              });

              _activeDangerZones.add(spotId);
              await _showDangerNotification(placeName, distance);
              print("🚨 [AUTO CHECK] DANGER: $placeName (${distance}km)");
            } else {
              print("➡️ [AUTO CHECK] Zone too far: $placeName (${distance}km > 1km)");
            }
          }

          if (dangerZones.isNotEmpty) {
            await _announceDangerZonesOnLoad(dangerZones);
          } else {
            print("✅ [AUTO CHECK] No danger zones found within 1km");
          }

          setState(() {
            _initialCheckDone = true;
          });
        } else {
          print("⚠️ [AUTO CHECK] API error: ${jsonData['message'] ?? 'No message'}");
        }
      } else {
        print("❌ [AUTO CHECK] HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ [AUTO CHECK] Error checking danger zones on load: $e");
    }
  }

  Future<void> _announceDangerZonesOnLoad(List<Map<String, dynamic>> dangerZones) async {
    if (dangerZones.isEmpty) return;

    await Future.delayed(Duration(milliseconds: 500));

    dangerZones.sort((a, b) => a['distance'].compareTo(b['distance']));

    String voiceMessage;

    if (dangerZones.length == 1) {
      var zone = dangerZones.first;
      voiceMessage = "⚠️ Alert! You are near a dangerous spot: ${zone['name']}. It is ${zone['distance'].toStringAsFixed(1)} kilometers away. Please be careful and stay alert.";
    } else {
      var nearest = dangerZones.first;
      voiceMessage = "⚠️ Alert! You are near ${dangerZones.length} dangerous locations. The nearest is ${nearest['name']}, ${nearest['distance'].toStringAsFixed(1)} kilometers away. Please stay alert and be careful.";
    }

    await _speakDangerAlert(voiceMessage);

    setState(() {
      _lastVoiceAlertTime = DateTime.now();
    });

    for (var zone in dangerZones) {
      _announcedDangerZones.add(zone['id'].toString());
    }

    Fluttertoast.showToast(
      msg: "⚠️ DANGER ZONE${dangerZones.length > 1 ? 'S' : ''} AHEAD! ${dangerZones.length} location${dangerZones.length > 1 ? 's' : ''} nearby",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );

    print("🔊 [AUTO CHECK] Voice alert announced for ${dangerZones.length} danger zones on page load");
  }

  Future<void> _initializeTextToSpeech() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setPitch(1.0);
      await flutterTts.setVolume(1.0);

      flutterTts.setCompletionHandler(() {
        setState(() {
          _isSpeaking = false;
        });
        print("🔊 TTS completed");
      });

      flutterTts.setErrorHandler((msg) {
        print("TTS Error: $msg");
        setState(() {
          _isSpeaking = false;
        });
      });

      flutterTts.setStartHandler(() {
        setState(() {
          _isSpeaking = true;
        });
        print("🔊 TTS started");
      });

      print("✅ Text-to-Speech initialized successfully for danger alerts");
    } catch (e) {
      print("❌ Error initializing TTS: $e");
    }
  }

  Future<void> _speakDangerAlert(String text) async {
    if (_isSpeaking) {
      print("🔊 Already speaking, skipping danger alert...");
      return;
    }

    try {
      await flutterTts.speak(text);
      print("🔊 Speaking danger alert: $text");
    } catch (e) {
      print("❌ Error speaking danger alert: $e");
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showDangerNotification(
      String placeName, double distance) async {
    int notificationId = placeName.hashCode.abs() % 10000;
    notificationId += DateTime.now().millisecondsSinceEpoch % 1000;

    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'danger_spots_channel',
      'Danger Spots Alerts',
      channelDescription: 'Alerts for nearby dangerous locations',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.red,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      ongoing: false,
      channelShowBadge: true,
      timeoutAfter: 60000,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    try {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        '⚠️ Danger Zone Alert',
        'Near dangerous area: $placeName\nDistance: ${distance.toStringAsFixed(2)} km',
        notificationDetails,
      );
      print("✅ [NOTIFICATION] Displayed notification for $placeName");
    } catch (e) {
      print("❌ [NOTIFICATION] Failed to show notification: $e");
    }
  }

  void _startContinuousDangerMonitoring() {
    if (_continuousCheckTimer != null) {
      _continuousCheckTimer!.cancel();
      _continuousCheckTimer = null;
    }

    print("🔄 [DANGER MONITOR] Starting continuous monitoring at ${DateTime.now()}");

    if (!_initialCheckDone) {
      _checkForDangerZones();
    }

    _continuousCheckTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) {
          if (!mounted) {
            print("❌ [DANGER MONITOR] Widget not mounted, stopping");
            timer.cancel();
            return;
          }

          if (_sosTriggered) {
            print("⚠️ [DANGER MONITOR] SOS triggered, skipping this check");
            return;
          }

          print("⏰ [DANGER MONITOR] Running scheduled check at ${DateTime.now()}");
          _checkForDangerZones();
        });
  }

  Future<void> _checkForDangerZones() async {
    try {
      print("📍 [${DateTime.now()}] Checking for dangerous spots...");

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        print("❌ Missing baseUrl or lid");
        return;
      }

      String url = "$baseUrl/user_view_nearbyDangerosSpot/";
      var response = await http.post(
        Uri.parse(url),
        body: {'lid': lid, 'radius': '2'},
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);

        if (jsonData['status'] == 'ok' && jsonData.containsKey('data')) {
          var spots = jsonData['data'];
          print("✅ Found ${spots.length} spots");

          Set<String> currentZones = {};
          Set<String> newlyEnteredZones = {};
          String nearestPlace = "Unknown location";
          double nearestDistance = 999.0;

          for (var spot in spots) {
            String spotId = spot['id'].toString();
            double distance =
                double.tryParse(spot['distance'].toString()) ?? 999.0;
            String placeName = spot['place'] ?? 'Unknown location';

            if (distance <= 2.0) {
              currentZones.add(spotId);

              if (distance < nearestDistance) {
                nearestDistance = distance;
                nearestPlace = placeName;
              }

              if (!_activeDangerZones.contains(spotId) && !_announcedDangerZones.contains(spotId)) {
                newlyEnteredZones.add(spotId);
              }

              await _showDangerNotification(placeName, distance);
              print("🚨 DANGER Notification sent for: $placeName (${distance}km)");
              _activeDangerZones.add(spotId);
            } else {
              print("➡️ Zone too far: $placeName (${distance}km > 1km)");
            }
          }

          if (newlyEnteredZones.isNotEmpty && _initialCheckDone) {
            await _announceDangerZonesWithVoice(newlyEnteredZones, nearestPlace, nearestDistance);
          }

          Set<String> zonesToRemove = _activeDangerZones.difference(currentZones);
          for (var zoneId in zonesToRemove) {
            print("✅ User left danger zone: $zoneId");
            _announcedDangerZones.remove(zoneId);
          }

          _activeDangerZones = currentZones;
          print("📊 Active danger zones count: ${_activeDangerZones.length}");
        } else {
          print("⚠️ API error: ${jsonData['message'] ?? 'No message'}");
        }
      } else {
        print("❌ HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error checking danger zones: $e");
    }
  }

  Future<void> _announceDangerZonesWithVoice(Set<String> newZoneIds, String nearestPlace, double nearestDistance) async {
    if (_lastVoiceAlertTime != null) {
      Duration timeSinceLastAlert = DateTime.now().difference(_lastVoiceAlertTime!);
      if (timeSinceLastAlert < _voiceAlertCooldown) {
        print("🔇 Voice alert in cooldown. Remaining: ${_voiceAlertCooldown - timeSinceLastAlert}");
        return;
      }
    }

    String voiceMessage;

    if (newZoneIds.length == 1) {
      voiceMessage = "⚠️ Alert! You are near a dangerous spot: $nearestPlace. It is ${nearestDistance.toStringAsFixed(1)} kilometers away. Please be careful and stay alert.";
    } else {
      voiceMessage = "⚠️ Alert! You are near ${newZoneIds.length} dangerous locations. The nearest is $nearestPlace, ${nearestDistance.toStringAsFixed(1)} kilometers away. Please stay alert and be careful.";
    }

    await _speakDangerAlert(voiceMessage);

    setState(() {
      _lastVoiceAlertTime = DateTime.now();
    });

    _announcedDangerZones.addAll(newZoneIds);

    Fluttertoast.showToast(
      msg: "⚠️ DANGER ZONE AHEAD: $nearestPlace (${nearestDistance.toStringAsFixed(1)}km)",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );

    print("🔊 Voice alert announced for ${newZoneIds.length} danger zones");
  }

  Future<void> _testVoiceAlert() async {
    await _speakDangerAlert("Test alert. This is a voice alert for dangerous spot detection system.");
    Fluttertoast.showToast(
      msg: "🔊 Voice alert test completed",
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.purple,
      textColor: Colors.white,
    );
  }

  Future<bool> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.storage,
      Permission.sensors,
      Permission.location,
      Permission.sms,
      Permission.notification
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);
    if (!allGranted) {
      Fluttertoast.showToast(
          msg: 'Microphone, storage, location and sensor permissions required');
    }
    return allGranted;
  }

  Future<void> _initAudioRecorder() async {
    try {
      await _audioRecorder.openRecorder();
      await _audioRecorder
          .setSubscriptionDuration(const Duration(milliseconds: 10));
      print("✅ Audio recorder initialized successfully");
    } catch (e) {
      print("❌ Error initializing audio recorder: $e");
    }
  }

  Future<void> _checkBackendURL() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String urls = sh.getString('url') ?? "";
    print("🔗 Stored backend URL: $urls");

    if (urls.isEmpty) {
      print("❌ No backend URL found in SharedPreferences!");
    } else {
      print("✅ Backend URL found: $urls");
    }
  }

  void _startMotionDetection() async {
    if (_accelerometerSubscription != null) {
      await _accelerometerSubscription?.cancel();
    }
    if (_gyroscopeSubscription != null) {
      await _gyroscopeSubscription?.cancel();
    }
    _motionSamplingTimer?.cancel();

    _motionDetectionActive = true;

    print("🔄 Starting shake detection system...");

    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
          if (mounted) {
            setState(() {
              _lastAccelerometer = event;
            });
            _checkForHardShake(event);
          }
        });

    _motionSamplingTimer =
        Timer.periodic(Duration(milliseconds: _samplingRate), (timer) {
          if (_lastAccelerometer != null) {
            _checkForHardShake(_lastAccelerometer!);
          }
        });

    print("✅ Shake detection started");
  }

  void _checkForHardShake(AccelerometerEvent event) {
    if (!_motionDetectionActive || _sosTriggered) return;

    double currentMagnitude =
    sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    _accelBuffer.add(currentMagnitude);
    if (_accelBuffer.length > _bufferSize) {
      _accelBuffer.removeAt(0);
    }

    double avgMagnitude = _accelBuffer.isNotEmpty
        ? _accelBuffer.reduce((a, b) => a + b) / _accelBuffer.length
        : currentMagnitude;

    double jerkX = (event.x - _prevAx).abs();
    double jerkY = (event.y - _prevAy).abs();
    double jerkZ = (event.z - _prevAz).abs();
    double totalJerk = jerkX + jerkY + jerkZ;

    _prevAx = event.x;
    _prevAy = event.y;
    _prevAz = event.z;

    if (avgMagnitude > 25 || totalJerk > 50) {
      print("📱 [SHAKE DEBUG] Magnitude: ${avgMagnitude.toStringAsFixed(2)}, "
          "Jerk: ${totalJerk.toStringAsFixed(2)}");
    }

    if (avgMagnitude > _shakeThreshold || totalJerk > 50) {
      DateTime now = DateTime.now();

      if (_lastShakeTime != null &&
          now.difference(_lastShakeTime!) > _shakeTimeout) {
        _shakeCount = 0;
        print("🔄 Reset shake count - timeout");
      }

      _shakeCount++;
      _lastShakeTime = now;

      print("📱 [SHAKE] Count: $_shakeCount/$_shakesNeeded, "
          "Magnitude: ${avgMagnitude.toStringAsFixed(2)}");

      if (_shakeCount >= _shakesNeeded) {
        print("🚨 [SHAKE DETECTED] Hard shake detected! Triggering SOS...");
        _triggerSOS();
        _shakeCount = 0;
      }
    }
  }

  void _setPhoneMotionDetected() {
    setState(() {
      _phoneMotionDetected = true;
    });
    _checkMultiFactorDetection();
    _startDetectionResetTimer();
  }

  void _setVoiceEmotionDetected() {
    setState(() {
      _voiceEmotionDetected = true;
    });
    _checkMultiFactorDetection();
    _startDetectionResetTimer();
  }

  void _checkMultiFactorDetection() {
    int detectedFactors = 0;
    if (_voiceTriggerDetected) detectedFactors++;
    if (_voiceEmotionDetected) detectedFactors++;
    if (_phoneMotionDetected) detectedFactors++;

    print("🔍 [MULTI-FACTOR] Detected factors: $detectedFactors");
    print("  - Voice Trigger: $_voiceTriggerDetected");
    print("  - Voice Emotion: $_voiceEmotionDetected");
    print("  - Phone Motion: $_phoneMotionDetected");
    _triggerSOSFromMultiFactor();
  }

  void _startDetectionResetTimer() {
    _detectionResetTimer?.cancel();
    _detectionResetTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _voiceTriggerDetected = false;
          _voiceEmotionDetected = false;
          _phoneMotionDetected = false;
        });
        print("🔄 [MULTI-FACTOR] Reset all detection flags");
      }
    });
  }

  Future<void> _triggerSOSFromMultiFactor() async {
    print("🚨 SOS FROM MULTI FACTOR");
    await _triggerSOS();
  }

  void _handleVolumeButtonPress() {
    print("🔊 Volume button pressed! Count: ${_volumeButtonPressCount + 1}");

    _volumeButtonTimer?.cancel();

    setState(() {
      _volumeButtonPressCount++;
    });

    _volumeButtonTimer = Timer(_volumePressTimeout, () {
      if (mounted) {
        setState(() {
          _volumeButtonPressCount = 0;
        });
        print("🔄 Volume button count reset");
      }
    });

    if (_volumeButtonPressCount >= _requiredVolumePresses) {
      _volumeButtonTimer?.cancel();
      setState(() {
        _volumeButtonPressCount = 0;
      });
      print("🚨 Volume button SOS triggered!");
      _triggerSOS();
    }
  }

  // UPDATED _triggerSOS METHOD WITH LOCATION
  Future<void> _triggerSOS() async {
    if (_sosTriggered) {
      print("⏳ SOS already triggered, please wait...");
      Fluttertoast.showToast(
        msg: 'SOS already activated. Please wait...',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    print("🚨 Starting SOS activation...");

    setState(() {
      _sosTriggered = true;
    });

    if (_isRecording) {
      print("🛑 Stopping recording...");
      await _stopRecording();
    }

    Fluttertoast.showToast(
      msg: '🚨 SOS ACTIVATED! Getting location and sending alerts...',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );

    try {
      // Get fresh location before sending SOS
      await _getCurrentLocation();

      print("📞 Calling SOS service with numbers: $phn");
      print("📍 Current location: $_currentLat, $_currentLng");

      await SOSService.triggerSOS(
        phone: phn,
        latitude: _currentLat,
        longitude: _currentLng,
      );

      print("✅ SOS service triggered successfully with location");
    } catch (e) {
      print("❌ Error triggering SOS service: $e");
      Fluttertoast.showToast(
        msg: 'Error sending SOS: $e',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }

    _sosCooldownTimer?.cancel();
    _sosCooldownTimer = Timer(Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _sosTriggered = false;
        });
        print("🔄 SOS cooldown complete - ready for next trigger");
        Fluttertoast.showToast(
          msg: 'SOS ready for activation',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
    });

    print("✅ SOS activation complete, cooldown timer started");
  }

  Future<void> _startRecording() async {
    if (_isRecording || _sosTriggered) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentAudioPath = '${tempDir.path}/audio$timestamp.m4a';

      await _audioRecorder.startRecorder(
        toFile: _currentAudioPath,
        codec: Codec.aacMP4,
        audioSource: AudioSource.microphone,
      );

      setState(() => _isRecording = true);

      _recordingTimer?.cancel();
      _recordingTimer = Timer(Duration(seconds: _recordingInterval), () async {
        if (_isRecording) {
          await _stopRecordingAndSend();
        }
      });

      print("🎤 Recording started");
    } catch (e) {
      setState(() => _isRecording = false);
      print("❌ Error starting recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (!_isRecording) return;
      await _audioRecorder.stopRecorder();
      setState(() => _isRecording = false);
      _recordingTimer?.cancel();
      print("🛑 Recording stopped");
    } catch (e) {
      setState(() => _isRecording = false);
      print("❌ Error stopping recording: $e");
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      if (!_isRecording || _sosTriggered) return;

      await _audioRecorder.stopRecorder();
      setState(() => _isRecording = false);
      _recordingTimer?.cancel();

      final audioFile = File(_currentAudioPath!);
      if (await audioFile.exists() && await audioFile.length() > 0) {
        await _sendAudioToBackend(_currentAudioPath!);
      }
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  Future<void> _sendAudioToBackend(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String url = prefs.getString('url') ?? '';
      if (url.isEmpty) return;

      print("🎤 Sending audio for emotion analysis...");

      final request =
      http.MultipartRequest('POST', Uri.parse('$url/myapp/recordings/'))
        ..files.add(await http.MultipartFile.fromPath(
          'audio',
          file.path,
          filename: 'child_audio.wav',
        ));

      final streamedResponse =
      await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var result = json.decode(response.body);

        String emotion = result['prediction'] ?? 'unknown';
        bool sosTriggered = result['sos_triggered'] ?? false;
        String sosReason = result['sos_reason'] ?? '';

        print("🎯 Emotion Analysis Result:");
        print("  - Emotion: $emotion");
        print("  - SOS Triggered: $sosTriggered");
        print("  - SOS Reason: $sosReason");

        if (sosTriggered && (emotion == 'fearful' || emotion == 'angry')) {
          _setVoiceEmotionDetected();
          print("✅ [EMOTION] Dangerous emotion detected: $emotion - SOS flag set");
        } else {
          print("✅ [EMOTION] Safe emotion: $emotion - No SOS needed");
        }

        await file.delete();
      } else {
        print("❌ Audio analysis failed: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Error sending audio: $e");
    }
  }

  bool isUserLogged = true;

  void stopSOSFeatures() {
    setState(() {
      _isListening = false;
    });

    if (_isRecording) {
      _stopRecording();
    }

    _motionSamplingTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _sosCooldownTimer?.cancel();
    _volumeButtonTimer?.cancel();
    _locationTimer?.cancel();

    _motionDetectionActive = false;
    _shakeCount = 0;
    _accelBuffer.clear();

    _voiceTriggerDetected = false;
    _voiceEmotionDetected = false;
    _phoneMotionDetected = false;

    _detectionResetTimer?.cancel();
    _volumeButtonTimer?.cancel();
    _recordingTimer?.cancel();

    _continuousCheckTimer?.cancel();
    _continuousCheckTimer = null;

    _activeDangerZones.clear();
    _announcedDangerZones.clear();

    print("🛑 [DANGER MONITOR] Stopped all features");
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _recordingTimer?.cancel();
    _motionSamplingTimer?.cancel();
    _detectionResetTimer?.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _volumeButtonTimer?.cancel();
    _continuousCheckTimer?.cancel();
    _sosCooldownTimer?.cancel();

    _audioRecorder.closeRecorder();
    flutterTts.stop();
    super.dispose();
  }

  void startSOSFeatures() {
    _motionDetectionActive = true;
    _shakeCount = 0;
    _accelBuffer.clear();
    _sosTriggered = false;
    _announcedDangerZones.clear();

    _requestPermissions();

    _initAudioRecorder();
    _checkBackendURL();
    _startMotionDetection();
    _startLocationUpdates(); // Start periodic location updates

    print("🔊 Setting up volume button listener...");
    try {
      platform.setMethodCallHandler((call) async {
        print("🔊 Method call received: ${call.method}");
        if (call.method == "volumeButtonPressed") {
          print("🔊 Volume button pressed event received");
          _handleVolumeButtonPress();
        }
        return null;
      });

      platform.invokeMethod('startVolumeButtonListener');
      print("✅ Volume button listener initialized");
    } catch (e) {
      print("❌ Error setting up volume button listener: $e");
    }

    print("🚀 [DEBUG] About to start danger monitoring...");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startContinuousDangerMonitoring();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: Row(
          children: [
            SizedBox(width: 8),
            Text("SafePath", style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          // Location indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                Icon(
                  _currentLat != 0.0 ? Icons.my_location : Icons.location_off,
                  color: _currentLat != 0.0 ? Colors.green : Colors.red,
                  size: 20,
                ),
              ],
            ),
          ),
          // Voice alert status indicator
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                Icon(
                  _isSpeaking ? Icons.volume_up : Icons.volume_off,
                  color: _isSpeaking ? Colors.amber : Colors.white,
                  size: 20,
                ),
                if (_isSpeaking) ...[
                  SizedBox(width: 4),
                  Text(
                    "ALERT",
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // SOS status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Icon(
                  _sosTriggered ? Icons.warning : Icons.security,
                  color: _sosTriggered ? Colors.red : Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  _sosTriggered ? "SOS ACTIVE" : "SOS READY",
                  style: TextStyle(
                    color: _sosTriggered ? Colors.red : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: _buildBeautifulDrawer(context),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', 0),
              const SizedBox(width: 40),
              _buildNavItem(Icons.contact_phone_rounded, 'Contact', 1),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          screens[selectedIndex],
          if (_isRecording)
            const Positioned(
              top: 50,
              right: 20,
              child: _StatusIndicator(
                  icon: Icons.mic, text: 'Recording', color: Colors.red),
            ),
          if (_isSpeaking)
            Positioned(
              top: 50,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.volume_up, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('DANGER ALERT',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          if (_sosTriggered)
            Positioned.fill(
              child: Container(
                color: Colors.red.withOpacity(0.1),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning,
                        size: 80,
                        color: Colors.red,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "SOS ACTIVE",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Help is on the way!",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBeautifulDrawer(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.shade50,
              Colors.white,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.pink.shade400,
                    Colors.pink.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: Colors.pink.shade400,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "SafePath",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Stay Safe • Stay Protected",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.shade400,
                      Colors.orange.shade600,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.shade300.withOpacity(0.5),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                // child:
                // ListTile(
                //   leading: Icon(Icons.warning_amber, color: Colors.white),
                //   title: Text(
                //     "False Alarm",
                //     style: TextStyle(
                //       color: Colors.white,
                //       fontWeight: FontWeight.w600,
                //       fontSize: 16,
                //     ),
                //   ),
                //   subtitle: Text(
                //     "Cancel accidental SOS alerts",
                //     style: TextStyle(
                //       color: Colors.white.withOpacity(0.9),
                //       fontSize: 13,
                //     ),
                //   ),
                //   trailing: Icon(Icons.arrow_forward_ios,
                //       color: Colors.white, size: 18),
                //   onTap: () => _showFalseAlarmDialog(context),
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                // ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.pink.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'JOURNEY MANAGEMENT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.history_outlined,
              title: "SOS History",
              subtitle: "View your SOS alerts",
              color: Colors.red.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const SOSHistoryPage()),
              ),
            ),

            _buildDrawerItem(
              icon: Icons.score_outlined,
              title: "Safety Prediction",
              subtitle: "Be Safe ",
              color: Colors.purple.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const SafetyPredictionPage()),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.add_location_alt_outlined,
              title: "Add Journey",
              subtitle: "Plan your travel route",
              color: Colors.purple.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const AddJourneyPage()),
              ),
            ),

            _buildDrawerItem(
              icon: Icons.route_outlined,
              title: "My Journeys",
              subtitle: "View your planned trips",
              color: Colors.blue.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ViewJourneysPage()),
              ),
            ),

            _buildDrawerItem(
              icon: Icons.people_outline,
              title: "Community Journeys",
              subtitle: "Explore others' trips",
              color: Colors.teal.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ViewAllJourneysPage()),
              ),
            ),

            _buildDrawerItem(
              icon: Icons.inbox_outlined,
              title: "Received Requests",
              subtitle: "Join requests for your trips",
              color: Colors.orange.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ViewReceivedRequestsPage()),
              ),
            ),

            _buildDrawerItem(
              icon: Icons.send_outlined,
              title: "Sent Requests",
              subtitle: "Track your join requests",
              color: Colors.green.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ViewSentRequestsPage()),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(
                color: Colors.grey.shade300,
                thickness: 1,
              ),
            ),

            _buildDrawerItem(
              icon: Icons.safety_check,
              title: "View Safe Points",
              subtitle: "Safe point",
              color: Colors.amber.shade600,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (ctx) => ViewSafePointsPage())),
            ),
            _buildDrawerItem(
              icon: Icons.safety_check,
              title: "View dangerous Points",
              subtitle: "dangerous point",
              color: Colors.amber.shade600,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) => ViewNearbyDangerousPointPage())),
            ),
            // In your _buildBeautifulDrawer method
            // _buildDrawerItem(
            //   icon: Icons.contact_emergency_outlined,
            //   title: "Emergency Contacts",
            //   subtitle: "Manage your emergency contacts",
            //   color: Colors.red.shade400,
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(builder: (ctx) => const EmergencyContactsPage()),
            //   ),
            // ),
            _buildDrawerItem(
              icon: Icons.lock_reset,
              title: "Change Password",
              subtitle: "Update security",
              color: Colors.purple.shade600,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) => UserChangePasswordPage())),
            ),
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: "View Profile",
              subtitle: "Your account",
              color: Colors.pink.shade400,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (ctx) => UserViewProfilePage())),
            ),
            _buildDrawerItem(
              icon: Icons.group,
              title: "Nearby Users",
              subtitle: "Connect safely",
              color: Colors.green.shade600,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (ctx) => NearbyUsersPage())),
            ),
            _buildDrawerItem(
              icon: Icons.dangerous,
              title: "Dangerous Spots",
              subtitle: "Marked locations",
              color: Colors.red.shade600,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (ctx) => DangerousSpotListPage())),
            ),

            Divider(
              height: 40,
              thickness: 1,
              color: Colors.grey.shade300,
              indent: 20,
              endIndent: 20,
            ),
            _buildDrawerItem(
              icon: Icons.score_outlined,
              title: "My Credit Score",
              subtitle: "View your blockchain score",
              color: Colors.purple.shade400,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const UserCreditScorePage()),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Colors.pink.shade400,
                      Colors.pink.shade600,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.shade300.withOpacity(0.5),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.white),
                  title: Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 18),
                  onTap: () => _showLogoutDialog(context),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> sendFalseAlarmSms(List<String> phoneNumbers) async {
    final Telephony telephony = Telephony.instance;

    final bool? permissionGranted = await telephony.requestSmsPermissions;

    if (permissionGranted != true) {
      Fluttertoast.showToast(msg: "❌ SMS permission denied");
      return;
    }

    final bool smsCapable = await telephony.isSmsCapable ?? false;
    if (!smsCapable) {
      Fluttertoast.showToast(msg: "❌ Device cannot send SMS");
      return;
    }

    const String message = "False Alarm. Situation is safe now.";

    int success = 0;
    int failed = 0;

    for (final String phone in phoneNumbers) {
      try {
        await telephony.sendSms(
          to: phone,
          message: message,
        );
        success++;
        debugPrint("✅ False alarm SMS sent to $phone");
      } catch (e) {
        failed++;
        debugPrint("❌ Failed to send to $phone : $e");
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    Fluttertoast.showToast(
      msg: "📩 False Alarm SMS → Sent: $success | Failed: $failed",
      gravity: ToastGravity.TOP,
      backgroundColor: failed == 0 ? Colors.green : Colors.orange,
      textColor: Colors.white,
    );
  }

  Future<bool> _sendFalseAlarmNotification(String password) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';

      if (baseUrl.isEmpty || lid.isEmpty) {
        print('❌ No backend URL or user ID found');
        return false;
      }

      String url = "$baseUrl/myapp/send_false_alarm/";

      var response = await http.post(
        Uri.parse(url),
        body: {
          'lid': lid,
          'password': password,
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        print('❌ HTTP error: ${response.statusCode}');
        return false;
      }

      var jsonData = json.decode(response.body);

      if (jsonData['status'] != 'ok') {
        print('❌ Backend rejected false alarm');
        return false;
      }

      List<String> phoneNumbers = [];

      String? contactsJson = prefs.getString('emergency_contacts');
      if (contactsJson != null && contactsJson.isNotEmpty) {
        phoneNumbers = List<String>.from(json.decode(contactsJson));
      } else if (jsonData.containsKey('contacts')) {
        phoneNumbers = List<String>.from(jsonData['contacts']);
      }

      if (phoneNumbers.isEmpty) {
        Fluttertoast.showToast(
          msg: "⚠️ No emergency contacts found",
          gravity: ToastGravity.TOP,
        );
        return true;
      }

      await sendFalseAlarmSms(phoneNumbers);

      Fluttertoast.showToast(
        msg: "✅ False alarm notification triggered",
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      return true;
    } catch (e) {
      print('❌ Exception sending false alarm: $e');

      Fluttertoast.showToast(
        msg: "❌ Failed to send false alarm",
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return false;
    }
  }

  void _showFalseAlarmDialog(BuildContext context) {
    TextEditingController _passwordController = TextEditingController();
    bool _isLoading = false;
    String _errorMessage = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.warning_amber,
                      size: 30,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'False Alarm Confirmation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Please enter your password to send False Alarm notification to your emergency contacts.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your account password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.lock),
                        errorText:
                        _errorMessage.isNotEmpty ? _errorMessage : null,
                      ),
                    ),
                    SizedBox(height: 10),
                    if (_isLoading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: CircularProgressIndicator(),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                    if (_passwordController.text.isEmpty) {
                      setState(() {
                        _errorMessage = 'Please enter your password';
                      });
                      return;
                    }

                    setState(() {
                      _isLoading = true;
                      _errorMessage = '';
                    });

                    bool success = await _sendFalseAlarmNotification(
                      _passwordController.text,
                    );

                    setState(() {
                      _isLoading = false;
                    });

                    if (success) {
                      Navigator.pop(context);
                      Fluttertoast.showToast(
                        msg:
                        'False Alarm notification sent to all contacts',
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.TOP,
                        backgroundColor: Colors.green,
                        textColor: Colors.white,
                      );
                    } else {
                      setState(() {
                        _errorMessage =
                        'Incorrect password. Please try again.';
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Send False Alarm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 22,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: 20,
          color: Colors.grey.shade400,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    size: 30,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Logout',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          SharedPreferences sh =
                          await SharedPreferences.getInstance();
                          String url = sh.getString('url') ?? "";
                          sh.clear();
                          sh.setString('url', url);
                          sh.setBool('isLogged', false);

                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() => selectedIndex = index);
  }

  final List<Widget> screens = [
    const MainHome(),
    const EmergencyContactsPage(),
  ];

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? Colors.pink : Colors.grey),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.pink : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _StatusIndicator(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class MainHome extends StatefulWidget {
  const MainHome({super.key});

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFE3EC),
                  Color(0xFFFFC2D6),
                  Color(0xFFFF8FB1),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "SafePath",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome Back,',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your safety is our priority',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSectionCard(
                    title: '🚨 Emergency Helpline Numbers',
                    color: Colors.red,
                    children: [
                      _buildHelplineItem('Women Helpline', '1091', Icons.phone),
                      _buildHelplineItem(
                          'National Emergency', '112', Icons.emergency),
                      _buildHelplineItem('Police', '100', Icons.local_police),
                      _buildHelplineItem('Cyber Crime', '1930', Icons.computer),
                      _buildHelplineItem(
                          'Child Helpline', '1098', Icons.child_care),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: '💡 Safety Tips',
                    color: Colors.orange,
                    children: [
                      _buildTipItem(
                          'Share your live location with trusted contacts when traveling'),
                      _buildTipItem(
                          'Trust your instincts - if something feels wrong, it probably is'),
                      _buildTipItem(
                          'Keep your phone charged and emergency numbers saved'),
                      _buildTipItem(
                          'Avoid isolated areas, especially during late hours'),
                      _buildTipItem(
                          'Be aware of your surroundings at all times'),
                      _buildTipItem('Learn basic self-defense techniques'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: '🥊 Quick Self-Defense Tips',
                    color: Colors.purple,
                    children: [
                      _buildTipItem(
                          'Target vulnerable areas: eyes, nose, throat, groin'),
                      _buildTipItem(
                          'Make noise - scream and attract attention'),
                      _buildTipItem(
                          'Use everyday items as weapons (keys, umbrella, bag)'),
                      _buildTipItem('Create distance and escape immediately'),
                      _buildTipItem(
                          'Never hesitate to fight back if in danger'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: '📱 Digital Safety',
                    color: Colors.blue,
                    children: [
                      _buildTipItem(
                          'Don\'t share personal information with strangers online'),
                      _buildTipItem(
                          'Use strong passwords and enable two-factor authentication'),
                      _buildTipItem(
                          'Be cautious of suspicious links and messages'),
                      _buildTipItem(
                          'Review privacy settings on social media regularly'),
                      _buildTipItem(
                          'Report cyberbullying and harassment immediately'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSectionCard(
                    title: '🚗 Travel Safety',
                    color: Colors.green,
                    children: [
                      _buildTipItem(
                          'Verify cab details before getting in (number plate, driver photo)'),
                      _buildTipItem(
                          'Sit in the back seat and keep doors locked'),
                      _buildTipItem(
                          'Share trip details with family or friends'),
                      _buildTipItem(
                          'Avoid traveling alone late at night when possible'),
                      _buildTipItem('Keep emergency contacts on speed dial'),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelplineItem(String name, String number, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.green),
            onPressed: () {
              openDialer(number);
            },
          ),
        ],
      ),
    );
  }

  void openDialer(String phoneNumber) async {
    final Uri dialUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(dialUri)) {
      await launchUrl(dialUri);
    } else {
      throw 'Could not open dialer';
    }
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}