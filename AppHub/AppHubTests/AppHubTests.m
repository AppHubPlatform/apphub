//
//  AppHubTests.m
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AppHub/AppHub.h>
#import <AppHubTestUtils/AppHubTestUtils.h>

#import <OCMock/OCMock.h>
#import <UIKit/UIKit.h>
#include <asl.h>

#import "AppHub+Private.h"
#import "AHConstants.h"
#import "AHLogging.h"
#import "AHFileSystem.h"
#import "AHPaths.h"
#import "AHBuildManager+Private.h"
#import "AppHubTestCase.h"
#import "AHReachability.h"

@interface AppHubTests : AppHubTestCase

@end

@implementation AppHubTests

-(BOOL) hasLogged:(NSString *)str {
    return [AHLogs() containsString:str];
}

-(void) fetchBuildWithCompletionHandler:(AHBuildResultBlock)completionHandler {
    __weak XCTestExpectation *fetchedBuild = [self expectationWithDescription:@"fetching a build"];
    [[AppHub buildManager] fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        completionHandler(result, error);
        [fetchedBuild fulfill];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

-(void) fetchTwoBuildsWithInitialCompletionHandler:(AHBuildResultBlock)initialCompletionHandler
                            finalCompletionHandler:(AHBuildResultBlock)completionHandler {
    XCTestExpectation *fetchedBuild = [self expectationWithDescription:@"fetching a build"];
    
    [[AppHub buildManager] fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        initialCompletionHandler(result, error);
        
        [[AppHub buildManager] fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
            completionHandler(result, error);
            [fetchedBuild fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

-(void) testWorkingBuildShouldHaveJsContents {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    NSDictionary *dict = [AppHubTestUtils buildInformationWithName:@"working-abc"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        NSString *bundlePath = result.bundle.bundlePath;
        
        XCTAssertEqualObjects(result.identifier, dict[AHBuildDataBuildIDKey]);
        XCTAssertEqualObjects(result.name, dict[AHBuildDataNameKey]);
        XCTAssertEqualObjects(result.buildDescription, dict[AHBuildDataDescriptionKey]);
        XCTAssertEqualObjects(result.compatibleIOSVersions, [dict[AHBuildDataCompatibleIOSVersionsKey] allValues]);
        
        NSTimeInterval creationDate = [result.creationDate timeIntervalSince1970];
        NSTimeInterval createdSeconds = [dict[AHBuildDataCreatedAtKey] doubleValue] / 1000;
        XCTAssertEqual(creationDate, createdSeconds);
       
        XCTAssertNotEqualObjects(result.bundle, [NSBundle mainBundle]);
        
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:bundlePath isDirectory:nil]);
    }];
}

-(void) testWorkingBuildShouldHaveJsContentsAsync {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    NSBundle *initialBundle = [AppHub buildManager].currentBuild.bundle;
    
    // The first time we run async, we shouldn't get the updated bundle.
    XCTAssertEqual([NSBundle mainBundle], initialBundle);
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        // But we should the second after the async result completes.
        
        NSBundle *updatedBundle = [AppHub buildManager].currentBuild.bundle;
        XCTAssertNotEqual(NSBundle.mainBundle, updatedBundle);
        XCTAssertEqual(result.bundle, updatedBundle);
    }];
}

-(void) testNilDefaultBundleUrl {
    [AppHub setApplicationID:nil];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertTrue([self hasLogged:@"No AppHub application id found"]);
    }];
}

-(void) testInvalidApplicationIdDoesNotLoadBundle {
    // Test that a json with a different application id does not get loaded.

    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    [AppHub setApplicationID:@"321"];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(result);
        XCTAssertTrue([self hasLogged:@"123 differs from expected: 321"]);
        XCTAssertEqual([AppHub buildManager].currentBuild.bundle, [NSBundle mainBundle]);
        
    }];
}

-(void) testDownNetworkDoesNotDownloadBundle {
    // Test that a json with a different application id does not get loaded.

    [AppHubTestUtils stubGetBuildRouteWithErrorCode:0];
    [AppHubTestUtils stubS3RouteWithIpaName:nil];

    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(result);
        XCTAssertEqual([NSBundle mainBundle], [AppHub buildManager].currentBuild.bundle);
        XCTAssertTrue([self hasLogged:@"Error fetching AppHub build information"]);
    }];
}

-(void) testMissingKeysReportsError {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/missing-s3-key.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(result);
        XCTAssertEqual([NSBundle mainBundle], [AppHub buildManager].currentBuild.bundle);
        XCTAssertTrue([self hasLogged:@"(ERROR) Missing key: s3_url"]);
    }];
}

-(void) testInvalidVersionsAreNotLoaded {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/invalid-version.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(result);
        XCTAssertEqual([NSBundle mainBundle], [AppHub buildManager].currentBuild.bundle);
        XCTAssertTrue([self hasLogged:@"Current version of app"]);
    }];
}

-(void) testS3DownloadError {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:nil];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(result);
        XCTAssertEqual([NSBundle mainBundle], [AppHub buildManager].currentBuild.bundle);
        XCTAssertTrue([self hasLogged:@"Error fetching AppHub build from S3"]);
    }];
}

-(void) testAppUpgradesShouldWipeBuilds {
    // We should clear out the build folder whenever the user installs a new version of the app.
    // TODO: we should actually not do this if the build is compatible with the new version of the app?
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertNotEqual([NSBundle mainBundle], result.bundle);
        
        // Now upgrade the version of the app to 1.1:
        self.mockNSBundle = [OCMockObject niceMockForClass:[NSBundle class]];
        NSBundle *newBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"MockBundles/Version1-1" ofType:@"bundle"]];
        [[[[self.mockNSBundle stub] classMethod] andReturn:newBundle] mainBundle];
        
        // Cleaning the builds should eliminate the old version.
        [[AppHub buildManager] cleanBuilds];
        
        XCTAssertEqual([NSBundle mainBundle], [AppHub buildManager].currentBuild.bundle);
    }];
}

-(void) testSdkVersion {
    XCTAssertTrue([[AppHub SDKVersion] isEqualToString:@"0.3.3"]);
}

-(void) testApiUrl {
    XCTAssertTrue([AHEndpoint isEqualToString:@"https://api.apphub.io/v1"]);
}

-(void) testNoBuildShouldGiveDefaultBundle {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/no-build.json"];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertEqual(result.bundle, [NSBundle mainBundle]);
        XCTAssertEqual([AppHub buildManager].currentBuild.bundle, result.bundle);
        XCTAssertFalse([self hasLogged:@"ERROR"]);
    }];
}

-(void) testNoBuildShouldRetainOriginalBundle {
    // Getting a no-build response should not clear the current bundle directory
    // until we restart the application.
    
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    __block NSString *oldBundlePath;
    
    [self fetchTwoBuildsWithInitialCompletionHandler:^(AHBuild *result, NSError *error) {
        oldBundlePath = result.bundle.bundlePath;
        
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:oldBundlePath isDirectory:nil]);
        [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/no-build.json"];
        
    } finalCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:oldBundlePath isDirectory:nil]);
    }];
}

-(void) testNoBuildShouldClearBuildDirectory {
    // Getting a "NO-BUILD" type should revert us to the original build.

    // First get a normal build.
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    __block NSBundle *oldBundle;
    
    [self fetchTwoBuildsWithInitialCompletionHandler:^(AHBuild *result, NSError *error) {
        oldBundle = result.bundle;
        XCTAssertNotEqual([NSBundle mainBundle], result.bundle);
        [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/no-build.json"];
    } finalCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertNotEqual(oldBundle, result.bundle);
        XCTAssertNotNil(result);
        XCTAssertEqual([NSBundle mainBundle], [AppHub buildManager].currentBuild.bundle);
        XCTAssertEqual([NSBundle mainBundle], result.bundle);
    }];
}

-(void) testInvalidBuildTypes {
    // Should report an error if we have an invalid build type.
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/invalid-build-type.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(result);
        XCTAssertEqual([NSBundle mainBundle], [AppHub buildManager].currentBuild.bundle);
        XCTAssertTrue([self hasLogged:@"(ERROR) Unknown build type"]);
    }];
}

-(void) testBrokenBuildShouldNotLoad {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/broken-build.zip"];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(result);
        XCTAssertEqual([NSBundle mainBundle], [AppHub buildManager].currentBuild.bundle);
    }];
}

-(void) testOldBuildsShouldGetDeleted {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    NSString *buildPath = AHBuildDirectory(@"ABC").path;
    
    [self fetchTwoBuildsWithInitialCompletionHandler:^(AHBuild *result, NSError *error) {
        // We should initially have a file at /ABC
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:buildPath isDirectory:nil]);
        [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-def.json"];
        
    } finalCompletionHandler:^(AHBuild *result, NSError *error) {
        NSString *newBuildPath = AHBuildDirectory(@"DEF").path;
        
        // The new build should exist.
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:newBuildPath isDirectory:nil]);
        
        // The old build should still exist, until we call "cleanBuilds" (this happens at startup only)
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:buildPath isDirectory:nil]);
        
        [[AppHub buildManager] cleanBuilds];
        XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:buildPath isDirectory:nil]);
    }];
}


-(void) testShouldNotRedownloadBuilds {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    __block AHBuild *cachedBuild;
    
    [self fetchTwoBuildsWithInitialCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertNotNil(result);
        cachedBuild = result;
        
    } finalCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertEqual(cachedBuild.bundle, result.bundle);
    }];
}

-(void) testAppUpgradesShouldNotWipeBuildsIfStillValid {
    // Don't wipe the build folder if our build is still valid.
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc-multiple-versions.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    NSString *buildPath = AHBuildDirectory(@"ABC").path;
    
    [self fetchTwoBuildsWithInitialCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:buildPath isDirectory:nil]);
        
        // Now upgrade the version of the app to 1.1:
        self.mockNSBundle = [OCMockObject niceMockForClass:[NSBundle class]];
        NSBundle *newBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:self.class] pathForResource:@"MockBundles/Version1-1" ofType:@"bundle"]];
        XCTAssertNotNil(newBundle);
        [[[[self.mockNSBundle stub] classMethod] andReturn:newBundle] mainBundle];
        
        [[AppHub buildManager] cleanBuilds];
    } finalCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:buildPath isDirectory:nil]);
    }];
}


-(void) testServerErrorBuildNoApplicationId {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/error-no-application-with-id.json" code:440];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-no-images.zip"];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        XCTAssertNotNil(error);
        XCTAssertNil(result);
        XCTAssertEqual([NSBundle mainBundle], [AppHub buildManager].currentBuild.bundle);
        XCTAssertTrue([self hasLogged:@"(ERROR) No project found with application ID \"123\""]);
    }];
}

-(void) testSetLogLevel {
    [AppHub setLogLevel:AHLogLevelWarning];
    
    XCTAssertEqual([AppHub logLevel], AHLogLevelWarning);
}

-(void) testSetApplicationId {
    [AppHub setApplicationID:@"foo"];
    XCTAssertEqual([AppHub applicationID], @"foo");
}

-(void) testTwoBundlesInTheSameBuild {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-two-bundles.zip"];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        NSString *bundlePath = result.bundle.bundlePath;
        NSString *firstBundle = [bundlePath stringByAppendingPathComponent:@"first.jsbundle"];
        NSString *secondBundle = [bundlePath stringByAppendingPathComponent:@"second.jsbundle"];
        
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:firstBundle isDirectory:nil]);
        XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:secondBundle isDirectory:nil]);
    }];
}

-(void) testBuildWithImages {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-images.zip"];

    UIImage *originalImage = [UIImage imageNamed:@"Pig"];

    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        UIImage *bundleImageAfterFetch = [UIImage imageNamed:@"Pig"];
        
        XCTAssertNotEqualObjects(bundleImageAfterFetch, originalImage);
    }];
}

-(void) testBuildOriginalImages {
    // We should keep the same image if the bundle does not contain the image.

    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-images.zip"];

    UIImage *originalImage = [UIImage imageNamed:@"Cow"];
    XCTAssertNotNil(originalImage);

    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        UIImage *bundleImage = [UIImage imageNamed:@"Cow"];
        XCTAssertEqualObjects(originalImage, bundleImage);
    }];
}

-(void) testNotificationCalledOnNewBuild {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-images.zip"];
    
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:AHBuildManagerDidMakeBuildAvailableNotification object:nil];
    
    [[observerMock expect] notificationWithName:AHBuildManagerDidMakeBuildAvailableNotification
                                         object:[AppHub buildManager]
                                       userInfo:[OCMArg checkWithBlock:^BOOL(NSDictionary *userInfo) {
                                                    AHBuild *build = [userInfo objectForKey:AHBuildManagerBuildKey];
                                                    XCTAssertNotEqual(build.bundle, [NSBundle mainBundle]);
                                                    return YES;
    }]];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        [observerMock verify];
        [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
    }];
}

-(void) testNotificationCalledOnPoll {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-images.zip"];
    
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:AHBuildManagerDidMakeBuildAvailableNotification object:nil];
    
    [[observerMock expect] notificationWithName:AHBuildManagerDidMakeBuildAvailableNotification
                                         object:[AppHub buildManager]
                                       userInfo:[OCMArg checkWithBlock:^BOOL(NSDictionary *userInfo) {
        AHBuild *build = [userInfo objectForKey:AHBuildManagerBuildKey];
        XCTAssertNotEqual(build.bundle, [NSBundle mainBundle]);
        
        return YES;
    }]];
    
    [AppHub buildManager].automaticPollingEnabled = YES;
    
    NSDate *runUntil = [NSDate dateWithTimeIntervalSinceNow:3.0];
    [[NSRunLoop currentRunLoop] runUntilDate:runUntil];
    
    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}

-(void) testNotificationCalledOnceWithPoll {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-images.zip"];
    
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:AHBuildManagerDidMakeBuildAvailableNotification object:nil];
    
    [[observerMock expect] notificationWithName:AHBuildManagerDidMakeBuildAvailableNotification
                                         object:[AppHub buildManager]
                                       userInfo:[OCMArg checkWithBlock:^BOOL(NSDictionary *userInfo) {
        AHBuild *build = [userInfo objectForKey:AHBuildManagerBuildKey];
        XCTAssertNotEqual(build.bundle, [NSBundle mainBundle]);
        
        return YES;
    }]];
    
    [AppHub buildManager].automaticPollingEnabled = YES;
    [[AppHub buildManager] fetchBuildWithCompletionHandler:nil];
    
    NSDate *runUntil = [NSDate dateWithTimeIntervalSinceNow:3.0];
    [[NSRunLoop currentRunLoop] runUntilDate:runUntil];
    
    [observerMock verify];
    [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
}

-(void) testNotificationCalledForAllHandlers {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-images.zip"];
    
    XCTestExpectation *firstExpection = [self expectationWithDescription:@"first expectation"];
    XCTestExpectation *secondExpectation = [self expectationWithDescription:@"second expectation"];
    
    [[AppHub buildManager] fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        [firstExpection fulfill];
    }];
    
    [[AppHub buildManager] fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        [secondExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

-(void) testNotificationNotCalledNoNewBuilds {
    [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/no-build.json"];
    [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.7/working-build-images.zip"];
    
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:AHBuildManagerDidMakeBuildAvailableNotification object:nil];
    
    [self fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        [observerMock verify];
        [[NSNotificationCenter defaultCenter] removeObserver:observerMock];
    }];
}

-(void) testDisablingAutomaticPolling {
    [AppHub buildManager].automaticPollingEnabled = NO;
    XCTAssertFalse([[AppHub buildManager] isAutomaticPollingEnabled]);
    
    [AppHub buildManager].automaticPollingEnabled = YES;
    XCTAssertTrue([[AppHub buildManager] isAutomaticPollingEnabled]);
}

-(void) testAutomaticPollingShouldCallMethod {
    id mock = OCMPartialMock([AppHub buildManager]);
    id reachabilityMock = OCMPartialMock([[AppHub sharedManager] reachability]);
    OCMStub([reachabilityMock isReachableViaWiFi]).andReturn(YES);
    
    XCTestExpectation *testExpection = [self expectationWithDescription:@"fetch build was called"];
    OCMStub([mock fetchBuildWithCompletionHandler:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        ((AHBuildManager *)mock).fetchingBuild = NO;
        [testExpection fulfill];
    });
    
    [AppHub buildManager].automaticPollingEnabled = YES;
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
    
    [mock stopMocking];
    [reachabilityMock stopMocking];
}

-(void) testAutomaticPollingShouldCallMethodWithCellularDownloadsEnabled {
    id mock = OCMPartialMock([AppHub buildManager]);
    id reachabilityMock = OCMPartialMock([[AppHub sharedManager] reachability]);
    OCMStub([reachabilityMock isReachableViaWiFi]).andReturn(NO);
    OCMStub([reachabilityMock isReachableViaWWAN]).andReturn(YES);
    
    [AppHub buildManager].cellularDownloadsEnabled = YES;
    
    XCTestExpectation *testExpection = [self expectationWithDescription:@"fetch build was called"];
    OCMStub([mock fetchBuildWithCompletionHandler:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        ((AHBuildManager *)mock).fetchingBuild = NO;
        [testExpection fulfill];
    });
    
    [AppHub buildManager].automaticPollingEnabled = YES;
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
    
    [mock stopMocking];
    [reachabilityMock stopMocking];
}

-(void) testAutomaticPollingShouldNotCallMethodWithoutWifi {
    id mock = OCMPartialMock([AppHub buildManager]);
    id reachabilityMock = OCMPartialMock([[AppHub sharedManager] reachability]);
    OCMStub([reachabilityMock isReachableViaWiFi]).andReturn(NO);
    
    OCMStub([mock fetchBuildWithCompletionHandler:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        ((AHBuildManager *)mock).fetchingBuild = NO;
        
        // This should not be called without a wifi connection.
        XCTAssert(false);
    });
    
    [AppHub buildManager].automaticPollingEnabled = YES;
    
    NSDate *runUntil = [NSDate dateWithTimeIntervalSinceNow: 1.0];
    [[NSRunLoop currentRunLoop] runUntilDate:runUntil];
    
    [mock stopMocking];
    [reachabilityMock stopMocking];
}


-(void) testReachability {
    XCTAssertFalse([[AppHub buildManager] areCellularDownloadsEnabled]);
    
    [AppHub buildManager].cellularDownloadsEnabled = YES;
    XCTAssertTrue([[AppHub buildManager] areCellularDownloadsEnabled]);
    
    [AppHub buildManager].cellularDownloadsEnabled = NO;
    XCTAssertFalse([[AppHub buildManager] areCellularDownloadsEnabled]);
}

-(void) testDebugBuilds {
    XCTAssertFalse([[AppHub buildManager] areDebugBuildsEnabled]);
    
    [AppHub buildManager].debugBuildsEnabled = YES;
    XCTAssertTrue([[AppHub buildManager] areDebugBuildsEnabled]);
    
    [AppHub buildManager].debugBuildsEnabled = NO;
    XCTAssertFalse([[AppHub buildManager] areDebugBuildsEnabled]);
}
                  
// Test multiple rootViews

@end
