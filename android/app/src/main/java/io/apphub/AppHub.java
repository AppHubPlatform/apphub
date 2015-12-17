package io.apphub;

import android.content.Context;

public class AppHub {

    private static final String SDKVersion = "0.0.1";
    private static AppHubLogLevel logLevel = AppHubLogLevel.ERROR;
    private static Context context;
    private static String rootURL;

    public static void initialize(Context context) {
        AppHub.context = context.getApplicationContext();
        AppHub.rootURL = "https://api.apphub.io/v1";
        AppHub.setLogLevel(AppHubLogLevel.DEBUG);
    }

    protected static Context getContext() {
        Context context = AppHub.context;
        if (context == null) {
            throw new IllegalStateException("Must initialize AppHub context: AppHub.initialize(...);");
        }
        return context;
    }

    public static void setLogLevel(AppHubLogLevel level) {
        AppHub.logLevel = level;
    }

    public static AppHubLogLevel getLogLevel() {
        return AppHub.logLevel;
    }

    public static String getSDKVersion() {
        return AppHub.SDKVersion;
    }

    protected static String getRootURL() {
        return rootURL;
    }

    protected static void setRootURL(String rootURL) {
        AppHub.rootURL = rootURL;
    }
}
