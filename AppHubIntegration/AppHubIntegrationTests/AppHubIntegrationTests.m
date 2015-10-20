/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <AppHub/AppHub.h>
#import <AppHubTestUtils/AppHubTestUtils.h>

#import "RCTAssert.h"
#import "RCTRedBox.h"
#import "RCTRootView.h"
#import "RCTBridgeModule.h"

#define TIMEOUT_SECONDS 2

@interface AppHubExampleTests : XCTestCase

@end

@implementation AppHubExampleTests

static XCTestExpectation *_newBuildExpectation;

-(void) setUp {
  [super setUp];
  AppHub.buildManager.automaticPollingEnabled = NO;
  [AppHubTestUtils clearBuilds];
  
  _newBuildExpectation = nil;
}

-(void) tearDown {
  [AppHubTestUtils tearDown];
  [super tearDown];
}

-(BOOL) findSubviewInView:(UIView *)view matching:(BOOL(^)(UIView *view))test
{
  if (test(view)) {
    return YES;
  }
  for (UIView *subview in [view subviews]) {
    if ([self findSubviewInView:subview matching:test]) {
      return YES;
    }
  }
  return NO;
}

-(void) fetchBuildSync {
  dispatch_semaphore_t sem = dispatch_semaphore_create(0);
  
  [[AppHub buildManager] fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
    XCTAssertNil(error);
    dispatch_semaphore_signal(sem);
  }];
  
  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
}

-(void) testExportingBuildInformation {
  UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
  NSDate *date = [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_SECONDS];
  BOOL foundElement = NO;
  
  while ([date timeIntervalSinceNow] > 0 && !foundElement) {
    [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [[NSRunLoop mainRunLoop] runMode:NSRunLoopCommonModes beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    foundElement = [self findSubviewInView:vc.view matching:^BOOL(UIView *view) {
      if ([view.accessibilityLabel isEqualToString:@"buildIdentifier:LOCALbuildName:LOCALbuildDescription:This build was downloaded from the App Store.buildCreatedAt:0buildCompatibleIOSVersions:1.0"]) {
        return YES;
      }
      return NO;
    }];
  }
  
  XCTAssertTrue(foundElement, @"Couldn't find element with text in %d seconds", TIMEOUT_SECONDS);
}

-(void) testNewBuildEvent {
  _newBuildExpectation = [self expectationWithDescription:@"found a new build"];
  
  [[NSNotificationCenter defaultCenter] addObserverForName:@"NEW-BUILD" object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
    NSDictionary *build = note.userInfo;
    XCTAssertEqualObjects(build[@"buildIdentifier"], @"LOCAL");
    [_newBuildExpectation fulfill];
  }];
  
  AHBuild *currentBuild = [AppHub buildManager].currentBuild;
  [[NSNotificationCenter defaultCenter] postNotificationName:AHBuildManagerDidMakeBuildAvailableNotification object:nil userInfo:@{AHBuildManagerBuildKey: currentBuild}];
  
  [self waitForExpectationsWithTimeout:5 handler:^(NSError *error) {
    XCTAssertNil(error);
  }];
}

-(void) testNewBuildJavaScript {
  [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
  [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.11/hello-world-2.zip"];
  
  [self fetchBuildSync];
  NSURL *jsCodeLocation = [[AppHub buildManager].currentBuild.bundle URLForResource:@"main"
                                                                      withExtension:@"jsbundle"];
  
  RCTRootView *view = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                  moduleName:@"HelloWorld"
                                           initialProperties:nil
                                                   launchOptions:nil];
  
  NSDate *date = [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_SECONDS];
  BOOL foundElement = NO;
  
  while ([date timeIntervalSinceNow] > 0 && !foundElement) {
    [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [[NSRunLoop mainRunLoop] runMode:NSRunLoopCommonModes beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    foundElement = [self findSubviewInView:view matching:^BOOL(UIView *view) {
      if ([view.accessibilityLabel containsString:@"hot code"] &&
          [view.accessibilityLabel containsString:@"ABC"]) {
        return YES;
      }
      return NO;
    }];
  }
  
  XCTAssertTrue(foundElement, @"Couldn't find element with text in %d seconds", TIMEOUT_SECONDS);
}

-(void) testNewBuildImage {
  [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-def.json"];
  [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.11/hello-world-images.zip"];
  
  [self fetchBuildSync];
  
  NSURL *jsCodeLocation = [[AppHub buildManager].currentBuild.bundle URLForResource:@"main"
                                                                             withExtension:@"jsbundle"];
  RCTRootView *view = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                  moduleName:@"HelloWorld"
                                           initialProperties:nil
                                               launchOptions:nil];
  
  NSDate *date = [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_SECONDS];
  BOOL foundElement = NO;
  
  while ([date timeIntervalSinceNow] > 0 && !foundElement) {
    [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [[NSRunLoop mainRunLoop] runMode:NSRunLoopCommonModes beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    foundElement = [self findSubviewInView:view matching:^BOOL(UIView *view) {
      if ([view isKindOfClass:[UIImageView class]]) {
        return YES;
      }
      return NO;
    }];
  }
  
  XCTAssertTrue(foundElement, @"Couldn't find element with text in %d seconds", TIMEOUT_SECONDS);
}

/*
-(void) testNewBuildImageIsRetainedAfterNewBuild {
  // Test that keep our images even when we load a new build
  [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-def.json"];
  [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.8/hello-world-images.zip"];
  
  [self fetchBuildSync];
  
  NSURL *jsCodeLocation = [[AppHub buildManager].currentBuild.bundle URLForResource:@"main"
                                                                      withExtension:@"jsbundle"];
  
  [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/no-build.json"];
  
  [self fetchBuildSync];
  
  RCTRootView *view = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                  moduleName:@"HelloWorld"
                                               launchOptions:nil];
  
  NSDate *date = [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_SECONDS];
  BOOL foundElement = NO;
  NSString *redboxError = nil;
  
  while ([date timeIntervalSinceNow] > 0 && !foundElement && !redboxError) {
    [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [[NSRunLoop mainRunLoop] runMode:NSRunLoopCommonModes beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    redboxError = [[RCTRedBox sharedInstance] currentErrorMessage];
    
    foundElement = [self findSubviewInView:view matching:^BOOL(UIView *view) {
      if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)view;
        XCTAssertNotNil(imageView.image);
        return YES;
      }
      return NO;
    }];
  }
  
  XCTAssertNil(redboxError, @"RedBox error: %@", redboxError);
  XCTAssertTrue(foundElement, @"Couldn't find element with text in %d seconds", TIMEOUT_SECONDS);
}
*/

@end
