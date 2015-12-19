/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <AppHub/AppHub.h>
#import <AppHubTestUtils/AppHubTestUtils.h>

#import "RCTAssert.h"
#import "RCTRedBox.h"
#import "RCTRootView.h"
#import "RCTBridgeModule.h"
#import "RCTText.h"

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

-(void) testExportingBuildInformation {
  UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
  NSDate *date = [NSDate dateWithTimeIntervalSinceNow:TIMEOUT_SECONDS];
  BOOL foundElement = NO;
  
  while ([date timeIntervalSinceNow] > 0 && !foundElement) {
    [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [[NSRunLoop mainRunLoop] runMode:NSRunLoopCommonModes beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    
    foundElement = [self findSubviewInView:vc.view matching:^BOOL(UIView *view) {
      if ([view.accessibilityLabel isEqualToString:@"buildIdentifier:LOCALbuildName:LOCALbuildDescription:This build was downloaded from the App Store.buildCreatedAt:buildCompatibleIOSVersions:1.0"]) {
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
  [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.17/hello-world-with-images.zip"];
  
  XCTestExpectation *testExpection = [self expectationWithDescription:@"Expect new JS code"];
  
  [[AppHub buildManager] fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
    NSURL *jsCodeLocation = [[AppHub buildManager].currentBuild.bundle URLForResource:@"main"
                                                                        withExtension:@"jsbundle"];
    RCTRootView *view = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                    moduleName:@"HelloWorld"
                                             initialProperties:nil
                                                 launchOptions:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      BOOL foundElement = [self findSubviewInView:view matching:^BOOL(UIView *view) {
        if ([view isKindOfClass:[RCTText class]]) {
          RCTText *textView = (RCTText *)view;
          return [textView.textStorage.string rangeOfString:@"buildIdentifier:ABC"].location != NSNotFound;
        } else {
          return NO;
        }
      }];
      
      XCTAssertTrue(foundElement, @"Couldn't find element with Text in %d seconds", TIMEOUT_SECONDS);
      [testExpection fulfill];
    });
    
  }];
  
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

-(void) testNewBuildImage {
  [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
  [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.17/hello-world-with-images.zip"];
  
  XCTestExpectation *testExpection = [self expectationWithDescription:@"Expect new JS image"];
  
  [[AppHub buildManager] fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
    NSURL *jsCodeLocation = [[AppHub buildManager].currentBuild.bundle URLForResource:@"main"
                                                                        withExtension:@"jsbundle"];
    RCTRootView *view = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                    moduleName:@"HelloWorld"
                                             initialProperties:nil
                                                 launchOptions:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
      __block UIImageView *element;
      BOOL foundElement = [self findSubviewInView:view matching:^BOOL(UIView *view) {
        if ( [view isKindOfClass:[UIImageView class]]) {
          element = (UIImageView *)view;
          return YES;
        } else {
          return NO;
        }
      }];
      
      XCTAssertTrue(foundElement, @"Couldn't find element with UIImageView in %d seconds", TIMEOUT_SECONDS);
      XCTAssertTrue(element.image, @"Couldn't find element with image in %d seconds", TIMEOUT_SECONDS);
      [testExpection fulfill];
    });
    
  }];
  
  [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
