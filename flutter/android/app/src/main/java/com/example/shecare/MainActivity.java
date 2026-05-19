package com.example.shecare;

import android.os.Bundle;
import android.view.KeyEvent;
import android.telephony.SmsManager;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "volume.channel";
    private MethodChannel methodChannel;
    private String latitude = "0.0";
    private String longitude = "0.0";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        methodChannel = new MethodChannel(
                getFlutterEngine().getDartExecutor().getBinaryMessenger(),
                CHANNEL
        );

        methodChannel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("updateLocation")) {
                try {
                    latitude = call.argument("latitude");
                    longitude = call.argument("longitude");
                    result.success("Location updated");
                } catch (Exception e) {
                    result.error("ERROR", "Failed to update location", e.getMessage());
                }
            } else if (call.method.equals("sendSms")) {
                try {
                    String phoneNumber = call.argument("phoneNumber");
                    String message = call.argument("message");
                    boolean smsSent = sendSmsNative(phoneNumber, message);
                    result.success(smsSent);
                } catch (Exception e) {
                    result.error("SMS_ERROR", "Failed to send SMS", e.getMessage());
                }
            } else {
                result.notImplemented();
            }
        });
    }

    private boolean sendSmsNative(String phoneNumber, String message) {
        try {
            SmsManager smsManager = SmsManager.getDefault();
            smsManager.sendTextMessage(phoneNumber, null, message, null, null);
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            if (methodChannel != null) {
                methodChannel.invokeMethod("volumeButtonPressed", null);
            }
            return true; // Prevent default volume behavior
        }
        return super.onKeyDown(keyCode, event);
    }

    @Override
    public boolean onKeyUp(int keyCode, KeyEvent event) {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            return true; // Prevent default volume behavior
        }
        return super.onKeyUp(keyCode, event);
    }
}