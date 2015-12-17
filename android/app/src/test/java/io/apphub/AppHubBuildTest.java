package io.apphub;

import org.json.JSONObject;
import org.junit.Test;

import java.util.Arrays;
import java.util.Date;
import java.util.HashSet;

import io.apphub.AppHubBuild;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

public class AppHubBuildTest extends AppHubTest {


    @Test
    public void testDefaultBuild() throws Exception {
        AppHubBuild build = new AppHubBuild();

        assertEquals("LOCAL_BUILD", build.getIdentifier());
        assertEquals("index.android.bundle", build.getBundleAssetPathWithName("index.android.bundle"));
    }

    @Test
    public void testBuildFromMetadata() throws Exception {
        String responseStr = readFile("responses/valid_get_build_response.json");
        JSONObject responseJson = new JSONObject(responseStr);
        AppHubBuild build = new AppHubBuild(responseJson.getJSONObject("data"));

        assertEquals(build.getIdentifier(), "ABC");
        assertEquals(build.getName(), "My Build");
        assertEquals(build.getProjectIdentifier(), "123");
        assertEquals(build.getCompatibleVersions(),
                new HashSet<>(Arrays.asList(new String[]{"1.0"})));
        assertEquals(build.getCreationDate(), new Date(1436336352118L));
        assertEquals(build.getDescription(), "Working");
        assertEquals(build.getS3Url(), "http://localhost:1111/amazon/abc");
    }
}