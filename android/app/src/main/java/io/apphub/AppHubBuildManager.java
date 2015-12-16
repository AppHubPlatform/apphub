package io.apphub;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.AsyncTask;
import android.preference.PreferenceManager;

import com.google.gson.Gson;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/**
 * Created by mata on 9/13/15.
 */
public class AppHubBuildManager {
    private final WeakReference<AppHubApplication> mApplication;

    // Protected to expose for testing.
    protected final String mSharedPreferencesLatestBuildIdKey;

    private final List<AppHubNewBuildListener> mNewBuildListeners = new ArrayList<>();

    private Boolean mDebugBuildsEnabled = false;
    private Boolean mAutomaticPollingEnabled = true;
    private Boolean mCellularDownloadsEnabled = false;

    protected AppHubBuildManager(AppHubApplication application) {
        mApplication = new WeakReference<>(application);
        mSharedPreferencesLatestBuildIdKey = "__APPHUB__/" + application.getApplicationID() + "/LATEST_BUILD_ID";

        new Timer().scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                pollForBuilds();
            }
        }, 0, 10 * 1000); // Every 10 seconds.
    }

    public AppHubBuild getLatestBuild() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(AppHub.getContext());
        String latestBuildId = prefs.getString(mSharedPreferencesLatestBuildIdKey, null);

        AppHubBuild.AppHubBuildInstanceCreator creator = new AppHubBuild.AppHubBuildInstanceCreator()
                .identifier(latestBuildId);

        if (latestBuildId == null) {
            return creator.createDefaultBuildInstance();
        } else {
            try {
                return creator.createInstanceFromMetadata();
            } catch (AppHubException e) {
                return creator.createDefaultBuildInstance();
            }
        }
    }

    public Boolean getDebugBuildsEnabled() {
        return mDebugBuildsEnabled;
    }

    public void setDebugBuildsEnabled(Boolean debugBuildsEnabled) {
        mDebugBuildsEnabled = debugBuildsEnabled;
    }

    public Boolean getAutomaticPollingEnabled() {
        return mAutomaticPollingEnabled;
    }

    public void setAutomaticPollingEnabled(Boolean automaticPollingEnabled) {
        mAutomaticPollingEnabled = automaticPollingEnabled;
        if (automaticPollingEnabled) {
            pollForBuilds();
        }
    }

    public Boolean getCellularDownloadsEnabled() {
        return mCellularDownloadsEnabled;
    }

    public void setCellularDownloadsEnabled(Boolean cellularDownloadsEnabled) {
        mCellularDownloadsEnabled = cellularDownloadsEnabled;
    }

    // Protected for testing.
    protected FetchBuildTask mRunningTask;
    private List<FetchBuildCallback> mFetchBuildCallbacks = new ArrayList<>();

    private void pollForBuilds() {
        ConnectivityManager connManager = (ConnectivityManager) AppHub.getContext()
                .getSystemService(Context.CONNECTIVITY_SERVICE);
        NetworkInfo wifi = connManager.getNetworkInfo(ConnectivityManager.TYPE_WIFI);

        if (mRunningTask != null || !mAutomaticPollingEnabled ||
                (! wifi.isConnected() && ! mCellularDownloadsEnabled)) {
            return;
        }

        fetchBuild(null);
    }

    public void fetchBuild(final FetchBuildCallback callback) {
        if (callback != null) {
            mFetchBuildCallbacks.add(callback);
        }

        if (mRunningTask == null) {
            mRunningTask = new FetchBuildTask();
            mRunningTask.execute(new FetchBuildCallback() {
                @Override
                public void done(AppHubBuild build, AppHubException e) {
                    mRunningTask = null;

                    for (FetchBuildCallback innerCallback : mFetchBuildCallbacks) {
                        innerCallback.done(build, e);
                    }

                    mFetchBuildCallbacks.clear();
                }
            });
        }
    }

    public void addNewBuildListener(AppHubNewBuildListener listener) {
        mNewBuildListeners.add(listener);
    }

    public void removeNewBuildListener(AppHubNewBuildListener listener) {
        mNewBuildListeners.remove(listener);
    }

    public void removeAllNewBuildListeners() {
        mNewBuildListeners.clear();
    }

    private class FetchBuildTask extends AsyncTask<FetchBuildCallback, Integer, Boolean> {
        private AppHubException error;
        private FetchBuildCallback callback;

        private static final String SERVER_RESPONSE_SUCCESS_TYPE = "success";
        private static final String SERVER_RESPONSE_STATUS_KEY = "status";

        private static final String SERVER_RESPONSE_BUILD_DATA_KEY = "data";

        private static final String BUILD_DATA_TYPE_KEY = "type";
        private static final String BUILD_DATA_GET_BUILD_TYPE = "GET-BUILD";
        private static final String BUILD_DATA_NO_BUILD_TYPE = "NO-BUILD";

        private class BuildInfo {
            private String uid;
            private String name;
            private String description;
            private String created;
            private String s3_url;
            private String project_uid;
            private JsonObject app_versions;

            protected BuildInfo() {
                // no-args constructor
            }

            protected List<String> getAppVersions() {
                List<String> appVersions = new ArrayList<>(app_versions.entrySet().size());

                for (Map.Entry<String,JsonElement> version : app_versions.entrySet()) {
                    appVersions.add(version.getValue().getAsString());
                }

                return appVersions;
            }

            protected String[] getAppVersionsArray() {
                List<String> appVersions = getAppVersions();
                return appVersions.toArray(new String[appVersions.size()]);
            }
        }

        private boolean unpackZip(File buildDirectory, File zipFile) throws AppHubException {
            ZipInputStream zis = null;
            try {
                String filename;
                InputStream is = new FileInputStream(zipFile);
                zis = new ZipInputStream(new BufferedInputStream(is));

                byte[] buffer = new byte[4096];
                int count;

                ZipEntry ze;
                while ((ze = zis.getNextEntry()) != null) {
                    filename = ze.getName();

                    // Need to create directories if not exists, or
                    // it will generate an Exception...
                    if (ze.isDirectory()) {
                        File fmd = new File(buildDirectory, filename);
                        fmd.mkdirs();
                        continue;
                    }

                    FileOutputStream fout = new FileOutputStream(new File(buildDirectory, filename));

                    while ((count = zis.read(buffer)) != -1) {
                        fout.write(buffer, 0, count);
                    }

                    fout.close();
                    zis.closeEntry();
                }

            } catch (IOException e) {
                throw new AppHubException(AppHubException.OTHER_CAUSE, "Error unzipping file.");
            } finally {
                try {
                    zis.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

            return true;
        }

        private boolean downloadFromBuildInfo(BuildInfo buildInfo) {
            AppHubBuild latestBuild = getLatestBuild();
            String applicationID = mApplication.get().getApplicationID();

            // Do not download if the new build matches our current build.
            if (latestBuild.getIdentifier().equals(buildInfo.uid)) {
                AppHubLog.d(String.format("Already downloaded build with ID: %s", buildInfo.uid));
                return true;
            }

            // Ensure that application ids match.
            if (! buildInfo.project_uid.equals(applicationID)) {
                error = new AppHubException(AppHubException.SERVER_FAILURE,
                        String.format("Build contains application ID: '%s', which differs from expected '%s",
                                buildInfo.project_uid, applicationID));
                return false;
            }

            // Ensure that the application is compatible with this version of the app.
            if (! buildInfo.getAppVersions().contains(AppHubUtils.getApplicationVersion())) {
                error = new AppHubException(AppHubException.SERVER_FAILURE,
                        String.format("Current version of app: '%s', is not contain in versions " +
                                        "in downloaded build: '%s", buildInfo.project_uid, applicationID));
                return false;
            }

            // Download the build and save it to a path.
            try {
                File buildDirectory = AppHubPaths.getDirectoryForBuildUid(buildInfo.uid);
                File zipFile = AppHubAPI.downloadFile(buildInfo.s3_url, buildDirectory);
                if (zipFile == null) {
                    error = new AppHubException(AppHubException.BUILD_DOWNLOAD_FAILURE,
                            String.format("Failed to download build from url %s to %s",
                                    buildInfo.s3_url, buildDirectory.getPath()));
                }

                boolean success = unpackZip(buildDirectory, zipFile);

                if (! success) {
                    throw new AppHubException(AppHubException.BUILD_DOWNLOAD_FAILURE,
                            String.format("Unable to uncompress zip file to dir: %s", buildDirectory.getPath()));
                }
            } catch (AppHubException e) {
                error = e;
                return false;
            }

            return true;
        }

        @Override
        protected Boolean doInBackground(FetchBuildCallback ... params) {
            callback = params[0];

            JsonObject object;
            try {
                object = AppHubAPI.getBuildData(mApplication.get());
            } catch (AppHubException e) {
                error = e;
                return false;
            } catch (IllegalStateException e) {
                error = new AppHubException(AppHubException.SERVER_FAILURE,
                        "Invalid server response: " + e.toString());
                return false;
            }

            String status = object.get(SERVER_RESPONSE_STATUS_KEY).getAsString();

            if (! status.equals(SERVER_RESPONSE_SUCCESS_TYPE)) {
                error = new AppHubException(AppHubException.INVALID_STATUS,
                            String.format("Invalid status: %s", status));
                return false;
            }

            JsonObject buildData = object.getAsJsonObject(SERVER_RESPONSE_BUILD_DATA_KEY);
            String buildDataType = buildData.getAsJsonPrimitive(BUILD_DATA_TYPE_KEY).getAsString();

            switch (buildDataType) {
                case BUILD_DATA_GET_BUILD_TYPE:
                    BuildInfo buildInfo = new Gson().fromJson(buildData, BuildInfo.class);
                    boolean success = downloadFromBuildInfo(buildInfo);
                    if (success) {
                        AppHubBuild build = new AppHubBuild.AppHubBuildInstanceCreator()
                                .identifier(buildInfo.uid)
                                .name(buildInfo.name)
                                .compatibleVersions(buildInfo.getAppVersionsArray())
                                .creationDate(new Date(Long.parseLong(buildInfo.created)))
                                .description(buildInfo.description)
                                .createInstance();
                        success = build.saveBuildMetadata();
                    }

                    if (success) {
                        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(AppHub.getContext());
                        success = prefs.edit().putString(mSharedPreferencesLatestBuildIdKey, buildInfo.uid).commit();
                    }

                    return success;

                case BUILD_DATA_NO_BUILD_TYPE:
                    // Clear the old build information. We will clean the build directory
                    // only at startup.

                    SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(AppHub.getContext());
                    return prefs.edit().remove(mSharedPreferencesLatestBuildIdKey).commit();

                default:
                    error = new AppHubException(AppHubException.OTHER_CAUSE,
                            String.format("Invalid build type: %s", buildDataType));
                    return false;
            }
        }

        @Override
        protected void onPostExecute(Boolean didSucceed) {
            if (didSucceed) {
                AppHubBuild newBuild = getLatestBuild();
                for (AppHubNewBuildListener listener : mNewBuildListeners) {
                    listener.onNewBuild(newBuild);
                }

                callback.done(newBuild, null);

            } else {
                if (error == null) {
                    error = new AppHubException(AppHubException.OTHER_CAUSE, "Unknown AppHub error.");
                }

                callback.done(null, error);
            }
        }
    }
}
