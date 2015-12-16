package io.apphub;

import org.junit.Test;

import java.util.Date;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

/**
 * Created by mata on 9/20/15.
 */
public class AppHubBuildTest extends AppHubTest {

    @Test
    public void testBuildBuilder() throws Exception {
        Date date = new Date();
        AppHubBuild build = new AppHubBuild.AppHubBuildInstanceCreator()
                                .identifier("foo")
                                .name("Name")
                                .compatibleVersions(new String[]{"1.0", "1.1"})
                                .creationDate(date)
                                .description("Build description")
                                .createInstance();

        assertEquals(build.getIdentifier(), "foo");
        assertEquals(build.getName(), "Name");
        assertArrayEquals(build.getCompatibleVersions(), new String[]{"1.0", "1.1"});
        assertEquals(build.getCreationDate().getTime(), date.getTime());
        assertEquals(build.getDescription(), "Build description");
    }

    @Test
    public void testDefaultBuild() throws Exception {
        AppHubBuild build = new AppHubBuild.AppHubBuildInstanceCreator()
                .createDefaultBuildInstance();

        assertEquals("LOCAL", build.getIdentifier());
        assertEquals("index.android.bundle", build.getBundleAssetPathWithName("index.android.bundle"));
    }

    @Test
    public void testBuildSerialization() throws Exception {
        Date date = new Date();
        AppHubBuild build = new AppHubBuild.AppHubBuildInstanceCreator()
                .identifier("foo")
                .name("Name")
                .compatibleVersions(new String[]{"1.0", "1.1"})
                .creationDate(date)
                .description("Build description")
                .createInstance();

        build.saveBuildMetadata();
        AppHubBuild buildClone = new AppHubBuild.AppHubBuildInstanceCreator()
                                        .identifier("foo")
                                        .createInstanceFromMetadata();

        assertTrue(build.equals(buildClone));
    }

    @Test(expected=AppHubException.class)
    public void testInvalidBuildDeserializationThrowsAppHubException() throws Exception {
        new AppHubBuild.AppHubBuildInstanceCreator()
                .identifier("foo")
                .createInstanceFromMetadata();
    }
}