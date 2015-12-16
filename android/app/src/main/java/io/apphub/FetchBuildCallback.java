package io.apphub;

/**
 * A {@code FetchBuildCallback} is used to return a new build from the AppHub server.
 */
public interface FetchBuildCallback {
    /**
     * Override this function with the code you want to run after the fetch is complete.
     *
     * @param build
     *          The object that was retrieved, or {@code null} if it did not succeed.
     *          If build is not nil, then it is guaranteed to be the most up to date build
     *          from the server.
     * @param e
     *          The exception raised by the fetch, or {@code null} if it succeeded.
     */
    public void done(AppHubBuild build, AppHubException e);

}
