package io.apphub;

import android.util.Log;

public class AppHubLog {

    private static void println(int priority, String tag, String message) {
        Log.println(priority, tag, message);
    }

    private static void log(AppHubLogLevel messageLogLevel, String message, Throwable tr) {
        if (messageLogLevel.getValue() >= AppHub.getLogLevel().getValue()) {
            if (tr == null) {
                println(messageLogLevel.getValue(), messageLogLevel.getStringValue(), message);
            } else {
                println(messageLogLevel.getValue(), messageLogLevel.getStringValue(),
                        message + '\n' + Log.getStackTraceString(tr));
            }
        }
    }

    /* package */ static void d( String message, Throwable tr) {
        log(AppHubLogLevel.DEBUG, message, tr);
    }

    /* package */ static void d(String message) {
        d(message, null);
    }

    /* package */ static void w(String message, Throwable tr) {
        log(AppHubLogLevel.WARNING, message, tr);
    }

    /* package */ static void w(String message) {
        w(message, null);
    }

    /* package */ static void e(String message, Throwable tr) {
        log(AppHubLogLevel.ERROR, message, tr);
    }

    /* package */ static void e(String message) {
        e(message, null);
    }
}
