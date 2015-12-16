package io.apphub;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.assertEquals;

/**
 * Created by mata on 9/13/15.
 */
public class AppHubApplicationTest extends AppHubBaseTest {

    @Before
    public void setUp() throws Exception {

    }

    @After
    public void tearDown() throws Exception {

    }

    @Test
    public void testGetApplicationID() throws Exception {
        AppHubApplication application = new AppHubApplication("foo");
        assertEquals(application.getApplicationID(), "foo");
    }
}