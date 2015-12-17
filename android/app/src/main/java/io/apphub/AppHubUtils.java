package io.apphub;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;

import java.io.File;

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

    protected static void deleteRecursively(File fileOrDirectory) {
        if (fileOrDirectory.isDirectory()) {
            for (File child : fileOrDirectory.listFiles()) {
                deleteRecursively(child);
            }
        }

        fileOrDirectory.delete();
    }
}
