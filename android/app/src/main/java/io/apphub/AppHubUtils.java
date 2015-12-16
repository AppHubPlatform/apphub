package io.apphub;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;

/**
 * Created by mata on 9/20/15.
 */
class AppHubUtils {

    protected static String getApplicationVersion() {
        Context context = AppHub.getContext();

        PackageInfo info;

        try {
            info = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
        } catch (PackageManager.NameNotFoundException e) {
            AppHubLog.e("No Android application version.", e);
            return null;
        }
        return info.versionName;
    }

}
