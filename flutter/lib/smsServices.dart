import 'package:telephony/telephony.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SmsService {
  static final Telephony telephony = Telephony.instance;

  static Future<void> sendAutoSms(
      List<String> numbers, String message) async {

    // 🔑 Request permission
    bool? granted = await telephony.requestSmsPermissions;
    if (granted != true) {
      Fluttertoast.showToast(msg: "❌ SMS permission denied");
      return;
    }

    try {
      for (String number in numbers) {
        print("📨 Sending SMS to $number");

        await telephony.sendSms(
          to: number,
          message: message,
        );
      }

      Fluttertoast.showToast(msg: "✅ SMS sent automatically");
    } catch (e) {
      Fluttertoast.showToast(msg: "❌ SMS failed: $e");
    }
  }
}
