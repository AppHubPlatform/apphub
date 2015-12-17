package io.apphub;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.lang.ref.WeakReference;
import java.util.Arrays;
import java.util.Date;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

public class AppHubBuild {
    private static final String DEFAULT_BUILD_IDENTIFIER = "LOCAL_BUILD";

    private final String mUid;
    private final String mProjectUid;
    private final String mBuildUrl;
    private final String mName;
    private final String mDescription;
    private final Date mCreated;
    private final Set<String> mCompatibleVersions;
    private final WeakReference<AppHubBuildManager> mBuildManager;

    public String getIdentifier() {
        return mUid;
    }

    public String getProjectIdentifier() {
        return mProjectUid;
    }

    public String getDescription() {
        return mDescription;
    }
    public String getBuildUrl() {
        return mBuildUrl;
    }

    public Date getCreationDate() {
        return mCreated;
    }

    public Set<String> getCompatibleVersions() {
        return mCompatibleVersions;
    }

    public String getName() {
        return mName;
    }

    public String getBundleAssetPathWithName(String assetName) {
        if (getIdentifier().equals(DEFAULT_BUILD_IDENTIFIER)) {
            return assetName;
        } else {
            return new File(getBuildDirectory(), assetName).getAbsolutePath();
        }
    }

    protected File getBuildDirectory() {
        return new File(mBuildManager.get().getRootBuildDirectory(), getIdentifier());
    }

    protected AppHubBuild(AppHubBuildManager manager, JSONObject obj) throws JSONException {
        mUid = obj.getString("uid");
        mProjectUid = obj.getString("project_uid");
        mBuildUrl = obj.getString("s3_url");
        mName = obj.getString("name");
        mDescription = obj.getString("description");
        mCreated = new Date(obj.getLong("created"));
        mCompatibleVersions = new HashSet<String>();
        mBuildManager = new WeakReference<AppHubBuildManager>(manager);

        Iterator<String> versions = obj.getJSONObject("app_versions").keys();
        while (versions.hasNext()) {
            mCompatibleVersions.add(versions.next());
        }
    }

    protected AppHubBuild(AppHubBuildManager manager) {
        mUid = DEFAULT_BUILD_IDENTIFIER;
        mProjectUid = null;
        mBuildUrl = null;
        mName = DEFAULT_BUILD_IDENTIFIER;
        mDescription = "This build was downloaded from the Play Store.";
        mCreated = new Date();
        mBuildManager = new WeakReference<AppHubBuildManager>(manager);
        mCompatibleVersions = new HashSet<String>(Arrays.asList(new String[]{BuildConfig.VERSION_NAME}));
    }
}
