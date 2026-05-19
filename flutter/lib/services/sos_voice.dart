import 'dart:async';
import 'package:shecare/services/sos_state.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;



class SOSVoice {
  final SOSState state;

  SOSVoice(this.state);

  Future<void> initSpeech() async {
    if (!state.toggleValue || !state.isUserOnHomePage) return;

    bool speechAvailable = await state.speech.initialize(
      onStatus: (status) {
        if (status == 'done' &&
            state.isListening &&
            !state.sosTriggered &&
            state.toggleValue &&
            state.isUserOnHomePage) {
          restartListening();
        }
      },
      onError: (error) {
        if (!state.sosTriggered &&
            state.toggleValue &&
            state.isUserOnHomePage) {
          Timer(const Duration(seconds: 2), restartListening);
        }
      },
    );

    if (speechAvailable) {
      state.isListening = true;
      startListening();
    }
  }

  void startListening() {
    if (state.speech.isListening ||
        state.sosTriggered ||
        !state.toggleValue ||
        !state.isUserOnHomePage) return;

    try {
      state.speech.listen(
        onResult: (result) {
          String recognizedText =
          result.recognizedWords.toLowerCase();

          for (String target in [
            "help",
            "emergency",
            "sos",
            "save me",
            "danger",
            "help me"
          ]) {
            if (recognizedText.contains(target) &&
                !state.sosTriggered &&
                state.isUserOnHomePage) {
              setVoiceTriggerDetected();
              break;
            }
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        localeId: "en_US",
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      print("❌ Error starting speech: $e");
    }
  }

  void restartListening() {
    if (!state.sosTriggered &&
        !state.speech.isListening &&
        state.toggleValue &&
        state.isUserOnHomePage) {
      Timer(const Duration(seconds: 1), startListening);
    }
  }

  void setVoiceTriggerDetected() {
    if (!state.toggleValue || !state.isUserOnHomePage) return;
    state.voiceTriggerDetected = true;
  }

  void setVoiceEmotionDetected() {
    if (!state.toggleValue || !state.isUserOnHomePage) return;
    state.voiceEmotionDetected = true;
  }
}
