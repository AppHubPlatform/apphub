package io.apphub;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.assertEquals;

public class AppHubApplicationTest extends AppHubBaseTest {

    @Test
    public void testGetApplicationID() throws Exception {
        AppHubApplication application = new AppHubApplication("foo");
        assertEquals(application.getApplicationID(), "foo");
    }
}