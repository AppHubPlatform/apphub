package io.apphub;

import android.content.Context;
import android.telephony.TelephonyManager;

import java.util.UUID;

public class AppHubApplication {
    private final String mApplicationID;
    private final AppHubBuildManager mBuildManager;

    public AppHubApplication(String applicationID) {
        mApplicationID = applicationID;
        mBuildManager = new AppHubBuildManager(this);
    }

    public String getApplicationID() {
        return mApplicationID;
    }

    public AppHubBuildManager getBuildManager() {
        return mBuildManager;
    }

    protected String getDeviceUUID() {
        Context context = AppHub.getContext();

        final TelephonyManager tm = (TelephonyManager) context.getSystemService(Context.TELEPHONY_SERVICE);

        final String tmDevice, tmSerial, androidId;
        tmDevice = "" + tm.getDeviceId();
        tmSerial = "" + tm.getSimSerialNumber();
        androidId = "" + android.provider.Settings.Secure.getString(context.getContentResolver(), android.provider.Settings.Secure.ANDROID_ID);

        UUID deviceUuid = new UUID(androidId.hashCode(), ((long)tmDevice.hashCode() << 32) | tmSerial.hashCode());
        return mApplicationID + "-" + deviceUuid.toString();
    }
}
