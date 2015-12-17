package io.apphub;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.util.Arrays;
import java.util.Date;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

/**
 * Created by mata on 9/20/15.
 */
public class AppHubBuild {
    private static final String DEFAULT_BUILD_IDENTIFIER = "LOCAL_BUILD";

    private final String mUid;
    private final String mProjectUid;
    private final String mS3Url;
    private final String mName;
    private final String mDescription;
    private final Date mCreated;
    private final Set<String> mCompatibleVersions;

    public String getIdentifier() {
        return mUid;
    }

    public String getProjectIdentifier() {
        return mProjectUid;
    }

    public String getDescription() {
        return mDescription;
    }
    public String getS3Url() {
        return mS3Url;
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
            return new File(AppHubPaths.getDirectoryForBuildUid(getIdentifier()), assetName)
                    .getAbsolutePath();
        }
    }

    protected AppHubBuild(JSONObject obj) throws JSONException {
        mUid = obj.getString("uid");
        mProjectUid = obj.getString("project_uid");
        mS3Url = obj.getString("s3_url");
        mName = obj.getString("name");
        mDescription = obj.getString("description");
        mCreated = new Date(obj.getLong("created"));
        mCompatibleVersions = new HashSet<String>();

        Iterator<String> versions = obj.getJSONObject("app_versions").keys();
        while (versions.hasNext()) {
            mCompatibleVersions.add(versions.next());
        }
    }

    protected AppHubBuild() {
        mUid = DEFAULT_BUILD_IDENTIFIER;
        mProjectUid = null;
        mS3Url = null;
        mName = DEFAULT_BUILD_IDENTIFIER;
        mDescription = "This build was downloaded from the Play Store.";
        mCreated = new Date();
        mCompatibleVersions = new HashSet<String>(Arrays.asList(new String[]{BuildConfig.VERSION_NAME}));
    }
}
