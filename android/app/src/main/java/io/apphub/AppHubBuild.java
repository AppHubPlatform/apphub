package io.apphub;

import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.InstanceCreator;

import java.io.File;
import java.lang.reflect.Type;
import java.util.Arrays;
import java.util.Date;

/**
 * Created by mata on 9/20/15.
 */
public class AppHubBuild {
    private static final String DEFAULT_BUILD_IDENTIFIER = "LOCAL";

    private final String mSharedPreferencesBuildMetadataKey;
    private final String mIdentifier;
    private final String mDescription;
    private final Date mCreationDate;
    private final String[] mCompatibleVersions;
    private final String mName;

    private AppHubBuild(AppHubBuildInstanceCreator builder) {
        mIdentifier = builder.identifier;
        mDescription = builder.description;
        mCreationDate = builder.creationDate;
        mCompatibleVersions = builder.compatibleVersions;
        mName = builder.name;
        mSharedPreferencesBuildMetadataKey = "__APPHUB__/" + mIdentifier + "/METADATA";
    }

    public String getIdentifier() {
        return mIdentifier;
    }

    public String getDescription() {
        return mDescription;
    }

    public Date getCreationDate() {
        return mCreationDate;
    }

    public String[] getCompatibleVersions() {
        return mCompatibleVersions;
    }

    public String getName() {
        return mName;
    }

    public String getBundleAssetPathWithName(String assetName) {
        if (mIdentifier.equals(DEFAULT_BUILD_IDENTIFIER)) {
            return assetName;
        } else {
            return new File(AppHubPaths.getDirectoryForBuildUid(mIdentifier), assetName)
                    .getAbsolutePath();
        }
    }

    protected static class AppHubBuildInstanceCreator implements InstanceCreator<AppHubBuild> {
        private String identifier;
        private String description;
        private Date creationDate;
        private String[] compatibleVersions;
        private String name;

        protected AppHubBuildInstanceCreator() {}

        protected AppHubBuildInstanceCreator identifier(String identifier) {
            this.identifier = identifier;
            return this;
        }

        protected AppHubBuildInstanceCreator description(String description) {
            this.description = description;
            return this;
        }

        protected AppHubBuildInstanceCreator creationDate(Date creationDate) {
            this.creationDate = creationDate;
            return this;
        }

        protected AppHubBuildInstanceCreator compatibleVersions(String[] compatibleVersions) {
            this.compatibleVersions = compatibleVersions;
            return this;
        }

        protected AppHubBuildInstanceCreator name(String name) {
            this.name = name;
            return this;
        }

        public AppHubBuild createInstanceFromMetadata() throws AppHubException {
            AppHubBuild build = new AppHubBuild(this);

            if (build.getIdentifier() == null) {
                throw new IllegalArgumentException("Missing key in createInstanceFromMetadata().");
            }

            Gson gson = new GsonBuilder()
                    .setVersion(1.0)
                    .registerTypeAdapter(AppHubBuild.class, new AppHubBuild.AppHubBuildInstanceCreator())
                    .create();

            SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(AppHub.getContext());

            String metadata;
            try {
                metadata = prefs.getString(build.mSharedPreferencesBuildMetadataKey, null);
            } catch (NullPointerException e) {
                metadata = null;
            }

            if (metadata == null) {
                AppHubLog.e("Missing metadata for build: " + build.mSharedPreferencesBuildMetadataKey);
                throw new AppHubException(AppHubException.BUILD_METADATA_NOT_FOUND,
                        "Missing metadata for build.");
            }

            return gson.fromJson(metadata, AppHubBuild.class);
        }

        public AppHubBuild createInstance() {
            AppHubBuild build = new AppHubBuild(this);

            if (build.getIdentifier() == null || build.getCompatibleVersions() == null ||
                    build.getCreationDate() == null || build.getDescription() == null ||
                    build.getName() == null) {
                throw new IllegalArgumentException("Missing constructor argument to AppHubBuild.");
            }

            return build;
        }

        // Used by gson.
        public AppHubBuild createInstance(Type type) {
            return new AppHubBuild(this);
        }

        public AppHubBuild createDefaultBuildInstance() {
            return this
                    .identifier(DEFAULT_BUILD_IDENTIFIER)
                    .description("This build was downloaded from the App Store.")
                    .name(DEFAULT_BUILD_IDENTIFIER)
                    .compatibleVersions(new String[]{ BuildConfig.VERSION_NAME })
                    .creationDate(new Date())
                    .createInstance();
        }

    }

    protected boolean saveBuildMetadata() {
        Gson gson = new Gson();
        String metadata = gson.toJson(this);

        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(AppHub.getContext());
        return prefs.edit().putString(mSharedPreferencesBuildMetadataKey, metadata).commit();
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        AppHubBuild that = (AppHubBuild) o;

        if (!mIdentifier.equals(that.mIdentifier)) return false;
        if (!mDescription.equals(that.mDescription)) return false;
        if (!mCreationDate.toString().equals(that.mCreationDate.toString())) return false;
        if (!Arrays.equals(mCompatibleVersions, that.mCompatibleVersions)) return false;
        return mName.equals(that.mName);

    }

    @Override
    public int hashCode() {
        int result = mIdentifier.hashCode();
        result = 31 * result + mDescription.hashCode();
        result = 31 * result + mCreationDate.toString().hashCode();
        result = 31 * result + Arrays.hashCode(mCompatibleVersions);
        result = 31 * result + mName.hashCode();
        return result;
    }
}
