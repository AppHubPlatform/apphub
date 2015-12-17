package io.apphub;

import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;

import java.io.File;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.get;
import static com.github.tomakehurst.wiremock.client.WireMock.stubFor;
import static com.github.tomakehurst.wiremock.client.WireMock.urlMatching;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

public class AppHubBuildManagerTest extends AppHubBaseTest {

    private AppHubApplication application;
    private AppHubBuildManager manager;


    @Before
    public void setUp() throws Exception {
        super.setUp();

        application = new AppHubApplication("123");
        manager = application.getBuildManager();
        manager.setAutomaticPollingEnabled(false);
    }

    @Before
    public void tearDown() throws Exception {
        super.tearDown();

        manager.removeAllNewBuildListeners();
    }

    @Test
    public void testGetDebugBuildsEnabled() throws Exception {
        assertFalse(manager.getDebugBuildsEnabled());

        manager.setDebugBuildsEnabled(true);
        assertTrue(manager.getDebugBuildsEnabled());
    }

    @Test
    public void testGetAutomaticPollingEnabled() throws Exception {
        assertFalse(manager.getAutomaticPollingEnabled());

        manager.setAutomaticPollingEnabled(true);
        assertTrue(manager.getAutomaticPollingEnabled());
    }

    @Test
    public void testGetCellularDownloadsEnabled() throws Exception {
        assertFalse(manager.getCellularDownloadsEnabled());

        manager.setCellularDownloadsEnabled(true);
        assertTrue(manager.getCellularDownloadsEnabled());
    }

    @Test
    public void testInvalidProjectID() throws Exception {
        final CountDownLatch signal = new CountDownLatch(1);

        stubFor(get(urlMatching(".*build.*")).willReturn(aResponse().withStatus(440)));

        manager.fetchBuild(new FetchBuildCallback() {
            @Override
            public void done(AppHubBuild build, AppHubException e) {
                assertEquals(440, e.getCode());
                assertTrue(e.getMessage().contains("No project found with applicationID"));
                signal.countDown();
            }
        });

        assertTrue(signal.await(2, TimeUnit.SECONDS));
    }

    @Test
    public void testInvalidServerResponse() throws Exception {
        final CountDownLatch signal = new CountDownLatch(1);

        stubFor(get(urlMatching(".*build.*"))
                .willReturn(aResponse().withStatus(200).withBody("blah")));

        manager.fetchBuild(new FetchBuildCallback() {
            @Override
            public void done(AppHubBuild build, AppHubException e) {
                assertEquals(500, e.getCode());
                assertTrue(e.getMessage().contains("cannot be converted to JSONObject"));
                signal.countDown();
            }
        });

        assertTrue(signal.await(2, TimeUnit.SECONDS));
    }

    @Test
    public void testIncorrectProjectUIDResponse() throws Exception {
        final CountDownLatch signal = new CountDownLatch(1);

        String responseStr = readFile("responses/invalid_project_uid_response.json");

        stubFor(get(urlMatching(".*build.*"))
                .willReturn(aResponse().withStatus(200).withBody(responseStr)));

        manager.fetchBuild(new FetchBuildCallback() {
            @Override
            public void done(AppHubBuild build, AppHubException e) {
                assertEquals(500, e.getCode());
                assertTrue(e.getMessage().contains("Build contains application ID"));
                signal.countDown();
            }
        });

        assertTrue(signal.await(2, TimeUnit.SECONDS));
    }

    @Test
    public void testInvalidVersionResponse() throws Exception {
        final CountDownLatch signal = new CountDownLatch(1);

        String responseStr = readFile("responses/invalid_app_version_response.json");

        stubFor(get(urlMatching(".*build.*"))
                .willReturn(aResponse().withStatus(200).withBody(responseStr)));

        manager.fetchBuild(new FetchBuildCallback() {
            @Override
            public void done(AppHubBuild build, AppHubException e) {
                assertEquals(500, e.getCode());
                assertTrue(e.getMessage().contains("is not contain in versions"));
                signal.countDown();
            }
        });

        assertTrue(signal.await(2, TimeUnit.SECONDS));
    }


    @Test
    public void testValidResponseCreatesBuildDirectory() throws Exception {
        final CountDownLatch signal = new CountDownLatch(1);

        String responseStr = readFile("responses/valid_get_build_response.json");
        stubFor(get(urlMatching(".*build.*"))
                .willReturn(aResponse().withStatus(200).withBody(responseStr)));

        stubFor(get(urlMatching(".*amazon.*"))
                .willReturn(aResponse().withStatus(200).withBodyFile("builds/react-0.11/no-images.zip")));

        manager.fetchBuild(new FetchBuildCallback() {
            @Override
            public void done(AppHubBuild build, AppHubException e) {
                assertEquals("ABC", build.getIdentifier());
                assertEquals("ABC", manager.getLatestBuild().getIdentifier());
                File f = new File(build.getBundleAssetPathWithName("index.android.bundle"));
                assertTrue(f.exists() && f.isFile());

                signal.countDown();
            }
        });

        assertTrue(signal.await(2, TimeUnit.SECONDS));
    }

    @Test
    public void testCleanBuildDoesNotRemoveCurrentBuild() throws Exception {
        final CountDownLatch signal = new CountDownLatch(1);

        String responseStr = readFile("responses/valid_get_build_response.json");
        stubFor(get(urlMatching(".*build.*"))
                .willReturn(aResponse().withStatus(200).withBody(responseStr)));

        stubFor(get(urlMatching(".*amazon.*"))
                .willReturn(aResponse().withStatus(200).withBodyFile("builds/react-0.11/no-images.zip")));

        manager.fetchBuild(new FetchBuildCallback() {
            @Override
            public void done(AppHubBuild build, AppHubException e) {
                manager.cleanBuilds();

                File f = new File(build.getBundleAssetPathWithName("index.android.bundle"));
                assertTrue(f.exists() && f.isFile());

                signal.countDown();
            }
        });

        assertTrue(signal.await(2, TimeUnit.SECONDS));
    }

    @Test
    public void testCleanBuildRemovesOldBuild() throws Exception {

        String responseStr = readFile("responses/valid_get_build_response.json");
        stubFor(get(urlMatching(".*build.*"))
                .willReturn(aResponse().withStatus(200).withBody(responseStr)));

        stubFor(get(urlMatching(".*amazon.*"))
                .willReturn(aResponse().withStatus(200).withBodyFile("builds/react-0.11/no-images.zip")));

        final CountDownLatch signal = new CountDownLatch(1);

        manager.fetchBuild(new FetchBuildCallback() {
            @Override
            public void done(final AppHubBuild build, AppHubException e) {
                File f = new File(build.getBundleAssetPathWithName("index.android.bundle"));
                assertTrue(f.exists() && f.isFile());

                signal.countDown();
            }
        });

        assertTrue(signal.await(2, TimeUnit.SECONDS));

        AppHubBuild b = manager.getLatestBuild();

        String noResponseStr = readFile("responses/valid_no_build_response.json");
        stubFor(get(urlMatching(".*build.*"))
                .willReturn(aResponse().withStatus(200).withBody(noResponseStr)));

        final CountDownLatch signal2 = new CountDownLatch(1);
        manager.fetchBuild(new FetchBuildCallback() {
            @Override
            public void done(AppHubBuild build, AppHubException e) {
                signal2.countDown();
            }
        });

        assertTrue(signal2.await(2, TimeUnit.SECONDS));

        File f = new File(b.getBundleAssetPathWithName("index.android.bundle"));
        assertTrue(f.exists() && f.isFile());
        manager.cleanBuilds();
        assertFalse(f.exists());
    }

    @Test
    public void testCleanBuildRemovesOldVersion() throws Exception {
        String responseData = new JSONObject(readFile("responses/valid_get_build_response.json"))
                .getJSONObject("data").toString();

        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(AppHub.getContext());
        prefs.edit().putString(manager.mSharedPreferencesLatestBuildJsonKey, responseData).apply();

        manager.cleanBuilds();
        assertEquals(prefs.getString(manager.mSharedPreferencesLatestBuildJsonKey, null), responseData);

        String oldResponseData = new JSONObject(readFile("responses/invalid_app_version_response.json"))
                .getJSONObject("data").toString();
        prefs.edit().putString(manager.mSharedPreferencesLatestBuildJsonKey, oldResponseData).apply();
        manager.cleanBuilds();
        assertNull(prefs.getString(manager.mSharedPreferencesLatestBuildJsonKey, null));
    }

    @Test
    public void testCleanBuildIsRunOnAppLaunch() throws Exception {
        String oldResponseData = new JSONObject(readFile("responses/invalid_app_version_response.json"))
                .getJSONObject("data").toString();
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(AppHub.getContext());
        prefs.edit().putString(manager.mSharedPreferencesLatestBuildJsonKey, oldResponseData).apply();

        new AppHubApplication("123");
        assertNull(prefs.getString(manager.mSharedPreferencesLatestBuildJsonKey, null));
    }

    @Test
    public void testNewBuildListeners() throws Exception {
        final CountDownLatch signal = new CountDownLatch(1);

        String responseStr = readFile("responses/valid_get_build_response.json");
        stubFor(get(urlMatching(".*build.*"))
                .willReturn(aResponse().withStatus(200).withBody(responseStr)));

        stubFor(get(urlMatching(".*amazon.*"))
                .willReturn(aResponse().withStatus(200).withBodyFile("builds/react-0.11/no-images.zip")));

        manager.addNewBuildListener(new AppHubNewBuildListener() {
            @Override
            public void onNewBuild(AppHubBuild build) {
                assertEquals("ABC", build.getIdentifier());
                assertEquals("ABC", manager.getLatestBuild().getIdentifier());
                signal.countDown();
            }
        });

        manager.fetchBuild(null);

        assertTrue(signal.await(2, TimeUnit.SECONDS));
    }

    @Test
    public void testRemoveBuildListener() throws Exception {
        final CountDownLatch signal = new CountDownLatch(1);

        String responseStr = readFile("responses/valid_get_build_response.json");
        stubFor(get(urlMatching(".*build.*"))
                .willReturn(aResponse().withStatus(200).withBody(responseStr)));

        stubFor(get(urlMatching(".*amazon.*"))
                .willReturn(aResponse().withStatus(200).withBodyFile("builds/react-0.11/no-images.zip")));

        AppHubNewBuildListener listener = new AppHubNewBuildListener() {
            @Override
            public void onNewBuild(AppHubBuild build) {
                signal.countDown();
            }
        };

        manager.addNewBuildListener(listener);
        manager.removeNewBuildListener(listener);

        manager.fetchBuild(null);

        assertFalse(signal.await(1, TimeUnit.SECONDS));
    }

    @Test
    public void testNoBuildResponseClearsCurrentBuild() throws Exception {
        final CountDownLatch signal = new CountDownLatch(1);

        String responseStr = readFile("responses/valid_no_build_response.json");
        stubFor(get(urlMatching(".*build.*"))
                .willReturn(aResponse().withStatus(200).withBody(responseStr)));

        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(AppHub.getContext());
        prefs.edit().putString(manager.mSharedPreferencesLatestBuildJsonKey, "foo").apply();

        manager.fetchBuild(new FetchBuildCallback() {
            @Override
            public void done(AppHubBuild build, AppHubException e) {
                assertEquals("LOCAL_BUILD", build.getIdentifier());
                assertEquals("LOCAL_BUILD", manager.getLatestBuild().getIdentifier());
                assertEquals(build.getBundleAssetPathWithName("index.android.bundle"),
                        "index.android.bundle");

                signal.countDown();
            }
        });

        assertTrue(signal.await(2, TimeUnit.SECONDS));
    }

    @Test
    public void testDisablingPollingDoesNotRunTask() throws Exception {
        manager.setAutomaticPollingEnabled(false);
        assertTrue(manager.mRunningTask == null);
    }

    @Test
    public void testAutomaticPollingShouldRunTask() throws Exception {
        final CountDownLatch signal = new CountDownLatch(1);

        String responseStr = readFile("responses/valid_get_build_response.json");
        stubFor(get(urlMatching(".*build.*"))
                .willReturn(aResponse().withStatus(200).withBody(responseStr)));

        stubFor(get(urlMatching(".*amazon.*"))
                .willReturn(aResponse().withStatus(200).withBodyFile("builds/react-0.11/no-images.zip")));

        AppHubNewBuildListener listener = new AppHubNewBuildListener() {
            @Override
            public void onNewBuild(AppHubBuild build) {
                signal.countDown();
            }
        };

        manager.addNewBuildListener(listener);

        manager.setCellularDownloadsEnabled(true);
        manager.setAutomaticPollingEnabled(true);

        assertTrue(signal.await(2, TimeUnit.SECONDS));
    }


}