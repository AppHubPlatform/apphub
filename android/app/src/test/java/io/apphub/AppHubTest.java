package io.apphub;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.assertEquals;

/**
 * Created by mata on 9 /11/15.
 */
public class AppHubTest extends AppHubBaseTest {

    @Before
    public void setUp() throws Exception {
        super.setUp();
    }

    @After
    public void tearDown() throws Exception {
        super.tearDown();
    }

    @Test
    public void testSetLogLevel() throws Exception {
        assertEquals(AppHub.getLogLevel(), AppHubLogLevel.ERROR);

        AppHub.setLogLevel(AppHubLogLevel.DEBUG);
        assertEquals(AppHub.getLogLevel(), AppHubLogLevel.DEBUG);
    }

    @Test
    public void testGetSDKVersion() throws Exception {
        assertEquals(AppHub.getSDKVersion(), "0.0.1");
    }

    @Test
    public void testGetRootURL() throws Exception {
        // Re-initialize AppHub.
        AppHub.initialize(getContext());
        assertEquals(AppHub.getRootURL(), "https://api.apphub.io/v1");
    }
}