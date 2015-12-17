package io.apphub;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.AsyncTask;
import android.preference.PreferenceManager;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

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

public class AppHubBuildManager {
    private final AppHubApplication mApplication;

    // Protected to expose for testing.
    protected final String mSharedPreferencesLatestBuildJsonKey;

    private final List<AppHubNewBuildListener> mNewBuildListeners = new ArrayList<AppHubNewBuildListener>();

    private Boolean mDebugBuildsEnabled = false;
    private Boolean mAutomaticPollingEnabled = true;
    private Boolean mCellularDownloadsEnabled = false;

    protected AppHubBuildManager(AppHubApplication application) {
        mApplication = application;
        mSharedPreferencesLatestBuildJsonKey = "__APPHUB__/" +
                application.getApplicationID() + "/LATEST_BUILD_JSON";

        cleanBuilds();

        new Timer().scheduleAtFixedRate(new TimerTask() {
            @Override
            public void run() {
                pollForBuilds();
            }
        }, 0, 10 * 1000); // Every 10 seconds.
    }

    private static final String ROOT_DIR_NAME = "__APPHUB__";

    protected File getRootBuildDirectory() {
        File rootDirectory = new File(AppHub.getContext().getFilesDir(), ROOT_DIR_NAME);
        return new File(rootDirectory, mApplication.getApplicationID());
    }

    protected void cleanBuilds() {
        AppHubBuild latestBuild = getLatestBuild();

        if (! latestBuild.getCompatibleVersions().contains(AppHubUtils.getApplicationVersion())) {
            // We upgraded versions of the app, we should clear the cache.

            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(AppHub.getContext());
            prefs.edit().remove(mSharedPreferencesLatestBuildJsonKey).commit();
        }

        File[] buildDirectories = getRootBuildDirectory().listFiles();
        if (buildDirectories == null) {
            buildDirectories = new File[0];
        }

        for (File f : buildDirectories) {
            if (! f.equals(getLatestBuild().getBuildDirectory())) {
                AppHubUtils.deleteRecursively(f);
            }
        }
    }

    public AppHubBuild getLatestBuild() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(AppHub.getContext());
        String latestBuildJson = prefs.getString(mSharedPreferencesLatestBuildJsonKey, null);

        if (latestBuildJson == null) {
            return new AppHubBuild(this);
        } else {
            try {
                return new AppHubBuild(this, new JSONObject(latestBuildJson));
            } catch (JSONException e) {
                AppHubLog.e("Failed to create build.", e);
                return new AppHubBuild(this);
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
    private List<FetchBuildCallback> mFetchBuildCallbacks = new ArrayList<FetchBuildCallback>();

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

                    FileOutputStream fout = new FileOutputStream(
                            new File(buildDirectory, filename));

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

        private boolean downloadFromBuildData(JSONObject buildData) throws JSONException {
            AppHubLog.d("Downloading from buildData: " + buildData.toString());
            AppHubBuild build = new AppHubBuild(mApplication.getBuildManager(), buildData);
            AppHubBuild latestBuild = getLatestBuild();
            String applicationID = mApplication.getApplicationID();

            // Do not download if the new build matches our current build.
            if (latestBuild.getIdentifier().equals(build.getIdentifier())) {
                AppHubLog.d(String.format("Already downloaded build with ID: %s",
                        build.getIdentifier()));
                return true;
            }

            // Ensure that application ids match.
            if (! build.getProjectIdentifier().equals(applicationID)) {
                error = new AppHubException(AppHubException.SERVER_FAILURE,
                        String.format("Build contains application ID: '%s', " +
                                        "which differs from expected '%s",
                                build.getProjectIdentifier(), applicationID));
                return false;
            }

            // Ensure that the application is compatible with this version of the app.
            if (! build.getCompatibleVersions().contains(AppHubUtils.getApplicationVersion())) {
                error = new AppHubException(AppHubException.SERVER_FAILURE,
                        String.format("Current version of app: '%s', is not contain in versions " +
                                        "in downloaded build: '%s", build.getProjectIdentifier(),
                                applicationID));
                return false;
            }

            // Download the build and save it to a path.
            try {
                File buildDirectory = build.getBuildDirectory();
                File zipFile = AppHubAPI.downloadFile(build.getBuildUrl(), buildDirectory);
                if (zipFile == null) {
                    error = new AppHubException(AppHubException.BUILD_DOWNLOAD_FAILURE,
                            String.format("Failed to download build from url %s to %s",
                                    build.getBuildUrl(), buildDirectory.getPath()));
                }

                boolean success = unpackZip(buildDirectory, zipFile);

                if (! success) {
                    throw new AppHubException(AppHubException.BUILD_DOWNLOAD_FAILURE,
                            String.format("Unable to uncompress zip file to dir: %s",
                                    buildDirectory.getPath()));
                }
            } catch (AppHubException e) {
                error = e;
                return false;
            }

            return true;
        }

        // Return whether we have a new build.
        @Override
        protected Boolean doInBackground(FetchBuildCallback ... params) {
            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(
                            AppHub.getContext());
            try {
                callback = params[0];

                JSONObject object;
                try {
                    object = AppHubAPI.getBuildData(mApplication);
                } catch (AppHubException e) {
                    error = e;
                    return false;
                } catch (IllegalStateException e) {
                    error = new AppHubException(AppHubException.SERVER_FAILURE,
                            "Invalid server response: " + e.toString());
                    return false;
                }

                String status = object.getString(SERVER_RESPONSE_STATUS_KEY);

                if (! status.equals(SERVER_RESPONSE_SUCCESS_TYPE)) {
                    error = new AppHubException(AppHubException.INVALID_STATUS,
                            String.format("Invalid status: %s", status));
                    return false;
                }

                JSONObject buildData = object.getJSONObject(SERVER_RESPONSE_BUILD_DATA_KEY);
                String buildDataType = buildData.getString(BUILD_DATA_TYPE_KEY);

                switch (buildDataType) {
                    case BUILD_DATA_GET_BUILD_TYPE:
                        boolean success = downloadFromBuildData(buildData);
                        if (success) {
                            success = prefs.edit().putString(mSharedPreferencesLatestBuildJsonKey,
                                    buildData.toString()).commit();
                        }

                        return success;

                    case BUILD_DATA_NO_BUILD_TYPE:
                        // Clear the old build information. We will clean the build directory
                        // only at startup.
                        prefs.edit().remove(mSharedPreferencesLatestBuildJsonKey).commit();
                        return false;

                    default:
                        error = new AppHubException(AppHubException.OTHER_CAUSE,
                                String.format("Invalid build type: %s", buildDataType));
                        return false;
                }
            } catch (JSONException e) {
                AppHubLog.e("Failed to parse JSON of build.", e);
                return false;
            }
        }

        @Override
        protected void onPostExecute(Boolean didDownloadNewBuild) {
            if (error == null) {
                if (didDownloadNewBuild) {
                    AppHubBuild newBuild = getLatestBuild();
                    for (AppHubNewBuildListener listener : mNewBuildListeners) {
                        listener.onNewBuild(newBuild);
                    }

                    callback.done(newBuild, null);
                } else {
                    callback.done(null, null);
                }
            } else {
                AppHubLog.e("Error downloading build:", error);
                callback.done(null, error);
            }
        }
    }
}
