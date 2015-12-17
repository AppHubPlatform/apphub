package io.apphub;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

class AppHubAPI {

    protected static JSONObject getBuildData(AppHubApplication application) throws AppHubException {
        String applicationID = application.getApplicationID();

        AppHubLog.d(String.format("Downloading build information for project: %s", applicationID));

        HttpURLConnection urlConnection = null;
        String responseString = "";

        try {
            URL url = new URL(String.format("%s/projects/%s/build?sdk_version=%s&app_version=%s&" +
                            "device_uid=%s&debug=%s", AppHub.getRootURL(), applicationID,
                    AppHub.getSDKVersion(), AppHubUtils.getApplicationVersion(),
                    application.getDeviceUUID(), application.getBuildManager().getDebugBuildsEnabled() ? "1" : "0"));
            urlConnection = (HttpURLConnection) url
                    .openConnection();

            switch (urlConnection.getResponseCode()) {
                case 200:
                case 201:
                    BufferedReader br = new BufferedReader(new InputStreamReader(urlConnection.getInputStream()));
                    StringBuilder sb = new StringBuilder();
                    String line;
                    while ((line = br.readLine()) != null) {
                        sb.append(line+"\n");
                    }
                    br.close();
                    responseString = sb.toString();
                    break;

                case 440:
                    throw new AppHubException(AppHubException.INVALID_PROJECT_ID,
                            String.format("No project found with applicationID '%s'", applicationID));

                case 441:
                    throw new AppHubException(AppHubException.OUTDATED_SDK,
                            String.format("It looks like your version of the SDK is out of date (%s). " +
                                    "Go to https://apphub.io/downloads to install a newer version " +
                                    "of the SDK.", AppHub.getSDKVersion()));

                default:
                    throw new AppHubException(AppHubException.OTHER_CAUSE,
                            "Unknown error code: " + String.valueOf(urlConnection.getResponseCode()));
            }
        } catch (IOException e) {
            throw new AppHubException(AppHubException.SERVER_FAILURE, e.toString());
        } finally {
            try {
                urlConnection.disconnect();
            } catch (Exception e) {
            }
        }

        try {
            return new JSONObject(responseString);
        } catch (JSONException e) {
            throw new AppHubException(AppHubException.SERVER_FAILURE, e.toString());
        }
    }

    private static final int BUFFER_SIZE = 4096;

    protected static File downloadFile(String fileURL, File saveDirectory) throws AppHubException {
        HttpURLConnection urlConnection = null;
        File tempFile = null;

        try {
            if (! saveDirectory.exists()) {
                saveDirectory.mkdirs();
            }

            URL url = new URL(fileURL);
            urlConnection = (HttpURLConnection) url.openConnection();
            int responseCode = urlConnection.getResponseCode();

            // always check HTTP response code first
            if (responseCode == HttpURLConnection.HTTP_OK) {

                // opens input stream from the HTTP connection
                InputStream inputStream = urlConnection.getInputStream();

                // opens an output stream to save into file
                tempFile = new File(saveDirectory, "tmp.zip");
                if (!tempFile.exists()) {
                    tempFile.createNewFile();
                }

                FileOutputStream outputStream = new FileOutputStream(tempFile);

                int bytesRead;
                byte[] buffer = new byte[BUFFER_SIZE];
                while ((bytesRead = inputStream.read(buffer)) != -1) {
                    outputStream.write(buffer, 0, bytesRead);
                }

                outputStream.close();
                inputStream.close();
            }
        } catch (IOException e) {
            throw new AppHubException(AppHubException.SERVER_FAILURE, e.toString());
        } finally {
            urlConnection.disconnect();
        }

        return tempFile;
    }
}
