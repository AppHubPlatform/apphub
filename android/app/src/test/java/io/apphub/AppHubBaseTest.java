package io.apphub;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.github.tomakehurst.wiremock.junit.WireMockRule;

import org.junit.After;
import org.junit.Before;
import org.junit.Ignore;
import org.junit.Rule;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricGradleTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;

/**
 * Created by mata on 9/15/15.
 */
@RunWith(RobolectricGradleTestRunner.class)
@Config(constants = BuildConfig.class)
@Ignore
public class AppHubBaseTest {

    @Rule
    public WireMockRule wireMockRule = new WireMockRule(1111);

    @Before
    public void setUp() throws Exception {
        AppHub.initialize(RuntimeEnvironment.application.getApplicationContext());

        AppHub.setRootURL("http://localhost:1111");
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(getContext());
        prefs.edit().clear().commit();

        AppHub.setLogLevel(AppHubLogLevel.ERROR);
    }

    @After
    public void tearDown() throws Exception {

    }

    public Context getContext() {
        return RuntimeEnvironment.application.getApplicationContext();
    }

    protected String readFile(String fileName) throws IOException {
        InputStream ins = this.getClass().getResourceAsStream("../../__files/" + fileName);
        BufferedReader br = new BufferedReader(new InputStreamReader(ins));
        try {
            StringBuilder sb = new StringBuilder();
            String line = br.readLine();

            while (line != null) {
                sb.append(line);
                sb.append("\n");
                line = br.readLine();
            }
            return sb.toString();
        } finally {
            br.close();
        }
    }
}
