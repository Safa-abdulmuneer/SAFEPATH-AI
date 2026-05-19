package com.example.shecare;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.SystemClock;

public class PowerButtonReceiver extends BroadcastReceiver {

    private static final long INTERVAL = 1500; // 1.5 sec
    private long[] mHits = new long[3]; // track 3 presses

    // Listener interface
    public interface SosTriggerListener {
        void onTriplePressDetected();
    }

    private SosTriggerListener listener;

    // Constructor
    public PowerButtonReceiver(SosTriggerListener listener) {
        this.listener = listener;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_SCREEN_OFF.equals(intent.getAction()) ||
                Intent.ACTION_SCREEN_ON.equals(intent.getAction())) {

            System.arraycopy(mHits, 1, mHits, 0, mHits.length - 1);
            mHits[mHits.length - 1] = SystemClock.uptimeMillis();

            if (mHits[0] >= (SystemClock.uptimeMillis() - INTERVAL)) {
                if (listener != null) listener.onTriplePressDetected();
            }
        }
    }
}
