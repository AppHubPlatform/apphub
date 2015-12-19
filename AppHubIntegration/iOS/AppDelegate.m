/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"

#import <AppHub/AppHub.h>
#import <AppHubTestUtils/AppHubTestUtils.h>

#import "RCTRootView.h"

@implementation AppDelegate

RCT_EXPORT_MODULE(AppHubExampleTests)

RCT_EXPORT_METHOD(newBuildFound:(NSDictionary *)build) {
  [[NSNotificationCenter defaultCenter] postNotificationName:@"NEW-BUILD" object:nil userInfo:build];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  //[AppHub buildManager].automaticPollingEnabled = NO;
  AHBuildManager *manager = [AppHub buildManager];
  
  [AppHub setApplicationID:@"123"];
  [AppHub setLogLevel:AHLogLevelDebug];
  
  manager.automaticPollingEnabled = NO;
  
  [AppHubTestUtils clearBuilds];
  
  // Comment from here.
//  [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
//  [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.17/hello-world-with-images.zip"];
//  
//  [[AppHub buildManager] fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
//    NSURL *jsCodeLocation = [manager.currentBuild.bundle URLForResource:@"main" withExtension:@"jsbundle"];
//    
//    RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
//                                                        moduleName:@"HelloWorld"
//                                                 initialProperties:nil
//                                                     launchOptions:launchOptions];
//    
//    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
//    UIViewController *rootViewController = [[UIViewController alloc] init];
//    rootViewController.view = rootView;
//    self.window.rootViewController = rootViewController;
//    [self.window makeKeyAndVisible];
//  }];
  // Comment to here.
  
  NSURL *jsCodeLocation = [manager.currentBuild.bundle URLForResource:@"main" withExtension:@"jsbundle"];
  
  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                      moduleName:@"HelloWorld"
                                               initialProperties:nil
                                                   launchOptions:launchOptions];
  
  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UIViewController *rootViewController = [[UIViewController alloc] init];
  rootViewController.view = rootView;
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];

  return YES;
}

@end
