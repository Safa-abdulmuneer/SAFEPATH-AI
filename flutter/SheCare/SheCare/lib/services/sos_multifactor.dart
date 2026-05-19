import 'dart:async';

import 'package:shecare/services/sos_state.dart';


class SOSMultiFactor {
  final SOSState state;

  SOSMultiFactor(this.state);

  void checkLastMotionForSOS(Map<String, dynamic> motionData) {
    if (state.sosTriggered ||
        !state.toggleValue ||
        !state.isUserOnHomePage) return;

    String motionType = motionData['motion_type'] ?? '';
    bool first3SecCompleted =
        motionData['first_3sec_completed'] ?? false;

    if ((motionType == "rapid_shake" || motionType == "throw") &&
        first3SecCompleted &&
        !state.sosTriggered) {
      setPhoneMotionDetected();
    }
  }

  void setPhoneMotionDetected() {
    if (!state.toggleValue || !state.isUserOnHomePage) return;

    state.phoneMotionDetected = true;
    checkMultiFactorDetection();
    startDetectionResetTimer();
  }

  void checkMultiFactorDetection() {
    if (!state.toggleValue || !state.isUserOnHomePage) return;

    int detected = 0;
    if (state.voiceTriggerDetected) detected++;
    if (state.voiceEmotionDetected) detected++;
    if (state.phoneMotionDetected) detected++;

    if (detected >= 2 && !state.sosTriggered) {
      triggerSOSFromMultiFactor();
    }
  }

  void startDetectionResetTimer() {
    state.detectionResetTimer?.cancel();
    state.detectionResetTimer =
        Timer(const Duration(seconds: 30), () {
          state.voiceTriggerDetected = false;
          state.voiceEmotionDetected = false;
          state.phoneMotionDetected = false;
        });
  }

  Future<void> triggerSOSFromMultiFactor() async {
    if (state.sosTriggered ||
        !state.toggleValue ||
        !state.isUserOnHomePage) return;

    state.sosTriggered = true;

    // 🔴 Actual SOS trigger will be called by controller
    print("🚨 SOS TRIGGERED FROM MULTI-FACTOR");
  }
}
