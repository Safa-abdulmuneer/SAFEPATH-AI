import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:telephony/telephony.dart';

class FalseAlarmPage extends StatefulWidget {
  final List<String> numbers;

  const FalseAlarmPage({super.key, required this.numbers});

  @override
  State<FalseAlarmPage> createState() => _FalseAlarmPageState();
}

class _FalseAlarmPageState extends State<FalseAlarmPage> {
  final Telephony telephony = Telephony.instance;

  bool sending = false;
  bool sent = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      sendFalseAlarm();
    });
  }

  /// ✅ Correct permission method for telephony
  Future<bool> requestSmsPermission() async {
    final bool? granted = await telephony.requestSmsPermissions;
    return granted ?? false;
  }

  Future<void> sendFalseAlarm() async {
    if (sending) return;

    // 🔒 Permission
    bool allowed = await requestSmsPermission();
    if (!allowed) {
      Fluttertoast.showToast(msg: "❌ SMS permission denied");
      return;
    }

    // 📵 Device check
    bool? isCapable = await telephony.isSmsCapable;
    if (!isCapable!) {
      Fluttertoast.showToast(msg: "❌ Device cannot send SMS");
      return;
    }

    setState(() {
      sending = true;
      sent = false;
      errorMessage = "";
    });

    const String message = "False Alarm. Situation is safe now.";

    int success = 0;
    int failed = 0;

    for (final phn in widget.numbers) {
      try {
        await telephony.sendSms(
          to: phn,
          message: message,
        );

        success++;
        debugPrint("✅ SMS sent to $phn");
      } catch (e) {
        failed++;
        debugPrint("❌ Failed to send to $phn : $e");
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      sending = false;
      sent = success > 0;
      if (failed > 0) {
        errorMessage = "$failed messages failed";
      }
    });

    Fluttertoast.showToast(
      msg: "Sent: $success | Failed: $failed",
      gravity: ToastGravity.TOP,
      backgroundColor: failed == 0 ? Colors.green : Colors.orange,
      textColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("False Alarm")),
      body: Center(
        child: sending
            ? const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 15),
            Text("Sending false alarm SMS...")
          ],
        )
            : sent
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle,
                color: Colors.green, size: 60),
            const SizedBox(height: 20),
            const Text(
              "False alarm sent successfully",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Go Back"),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 15),
            Text(errorMessage.isEmpty
                ? "Failed to send messages"
                : errorMessage),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendFalseAlarm,
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }
}
