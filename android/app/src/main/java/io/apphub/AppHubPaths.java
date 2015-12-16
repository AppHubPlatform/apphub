package io.apphub;

import java.io.File;

/**
 * Created by mata on 9/21/15.
 */
class AppHubPaths {
    private static final String ROOT_DIR_NAME = "__APPHUB__";
    private static final String BUILD_DIR_NAME = "builds";

    protected static File getRootDirectory() {
        return new File(AppHub.getContext().getFilesDir(), ROOT_DIR_NAME);
    }

    protected static File getBuildDirectory() {
        return new File(getRootDirectory(), BUILD_DIR_NAME);
    }

    protected static File getDirectoryForBuildUid(String buildUid) {
        return new File(getBuildDirectory(), buildUid);
    }
}
