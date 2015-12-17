package io.apphub;

public class AppHubException extends Exception {
    private static final long serialVersionUID = 1;
    private int code;

    public static final int OTHER_CAUSE = -1;

    /**
     * Error code indicating that the build metadata for a particular build is not found.
     */
    public static final int BUILD_METADATA_NOT_FOUND = 100;


    /**
     * Error code indicating that the Android application does not have a version string.
     */
    public static final int MISSING_APPLICATION_VERSION = 101;


    /**
     * Error code indicating that the version of the AppHub SDK is outdated.
     */
    public static final int OUTDATED_SDK = 102;

    /**
     * Error code indicating that the status of your AppHub project is invalid.
     */
    public static final int INVALID_STATUS = 103;

    /**
     * Error code indicating that the AppHub server failed to respond to a build request.
     */
    public static final int SERVER_FAILURE = 500;

    /**
     * Error code indicating that the AppHub server failed to serve a new build.
     */
    public static final int BUILD_DOWNLOAD_FAILURE = 501;

    /**
     * Error code indicating that there is no build with a given project ID.
     */
    public static final int INVALID_PROJECT_ID = 440;

    /**
     * Construct a new AppHubException with a particular error code.
     *
     * @param theCode
     *          The error code to identify the type of exception.
     * @param theMessage
     *          A message describing the error in more detail.
     */
    public AppHubException(int theCode, String theMessage) {
        super(theMessage);

        AppHubLog.e(theMessage);

        code = theCode;
    }

    /**
     * Construct a new AppHubException with an external cause.
     *
     * @param message
     *          A message describing the error in more detail.
     * @param cause
     *          The cause of the error.
     */
    public AppHubException(int theCode, String message, Throwable cause) {
        super(message, cause);

        AppHubLog.e(message, cause);
        code = theCode;
    }

    /**
     * Construct a new AppHubException with an external cause.
     *
     * @param cause
     *          The cause of the error.
     */
    public AppHubException(Throwable cause) {
        super(cause);

        AppHubLog.e("Exception", cause);
        code = OTHER_CAUSE;
    }

    /**
     * Access the code for this error.
     *
     * @return The numerical code for this error.
     */
    public int getCode() {
        return code;
    }
}
