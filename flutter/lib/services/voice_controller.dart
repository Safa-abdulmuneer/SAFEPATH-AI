import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';

import 'sos_state.dart';
import 'sos_controller.dart';

class VoiceController {
  final SOSState state;
  final SOSController sosController;

  final SpeechToText _speech = SpeechToText();

  VoiceController(this.state, this.sosController);

  final List<String> targetWords = [
    "help",
    "sos",
    "emergency",
    "save me",
    "danger",
    "help me",
  ];

  Future<void> startListening() async {
    if (state.isListening) return;

    bool available = await _speech.initialize(
      onStatus: (status) {
        // When speech stops, restart listening
        if (status == 'done' && state.isListening) {
          _restartListening();
        }
      },
      onError: (_) {
        state.isListening = false;
      },
    );

    if (!available) return;

    state.isListening = true;
    _listen();
  }
  void _listen() {
    if (_speech.isListening) return;

    _speech.listen(
      localeId: "en_US",
      partialResults: true,
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      cancelOnError: true,
      listenMode: ListenMode.dictation, // ✅ IMPORTANT
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        print("🎤 Heard: $text");

        for (final word in targetWords) {
          if (text.contains(word)) {
            sosController.onVoiceTriggerDetected();
            stopListening();
            break;
          }
        }
      },
    );
  }



  void _restartListening() {
    if (!state.isListening) return;

    if (!_speech.isListening) {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (state.isListening) {
          _listen();
        }
      });
    }
  }



  void stopListening() {
    if (!state.isListening) return;
    _speech.stop();
    state.isListening = false;
  }


  void dispose() {
    _speech.stop();
  }
}
