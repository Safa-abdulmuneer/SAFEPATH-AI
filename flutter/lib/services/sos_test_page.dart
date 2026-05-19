import 'package:flutter/material.dart';
import 'package:shecare/services/sos_controller.dart';
import 'package:shecare/services/sos_state.dart';
import 'package:shecare/services/voice_controller.dart';



class SOSTestPage extends StatefulWidget {
  const SOSTestPage({super.key});

  @override
  State<SOSTestPage> createState() => _SOSTestPageState();
}

class _SOSTestPageState extends State<SOSTestPage> {
  late SOSState state;
  late SOSController controller;
  late VoiceController voiceController;


  @override
  void initState() {
    super.initState();
    state = SOSState();
    controller = SOSController(state);
    voiceController = VoiceController(state, controller);
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOS Test")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text("SOS Toggle"),
              value: state.toggleValue,
              onChanged: (v) {
                setState(() {
                  state.toggleValue = v;
                });

                if (v) {
                  controller.start();
                } else {
                  controller.stop();
                }
              },

            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                await voiceController.startListening();
                setState(() {});
              },
              child: const Text("Start Voice Listening"),
            ),

            const SizedBox(height: 10),
            Text("Listening: ${state.isListening}"),

            const SizedBox(height: 10),
            Text("Voice Trigger: ${state.voiceTriggerDetected}"),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  controller.onMotionDetected();
                });
              },


              child: const Text("Simulate Motion Trigger"),
            ),
            const SizedBox(height: 20),
            Text(
              "SOS Triggered: ${state.sosTriggered}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: state.sosTriggered ? Colors.red : Colors.black,
              ),
            ),


            const SizedBox(height: 10),
            Text("Motion Trigger: ${state.phoneMotionDetected}"),

            const SizedBox(height: 20),
            Text("Toggle: ${state.toggleValue}"),
            Text("Listening: ${state.isListening}"),
            Text("Recording: ${state.isRecording}"),
            Text("SOS Triggered: ${state.sosTriggered}"),
          ],
        ),
      ),
    );
  }
}
