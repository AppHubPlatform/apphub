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
  manager.automaticPollingEnabled = NO;
  
  [AppHubTestUtils clearBuilds];
  
  
//  [[AppHub buildManager] fetchBuildWithCompletionHandler:nil];
//  // Create a root view controller and present it...
//  
//  [AppHub presentSelectorOnViewController:vc
//                         withBuildHandler:^(AHBuild *result, NSError *error) {
//    NSURL *jsCodeLocation = [result.bundle URLForResource:@"main"
//                                            withExtension:@"jsbundle"];
//    // Now initialize an RCTRootView with this bundle.
//  }];
  
//  [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
//  [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.11/hello-world-images.zip"];
//  dispatch_semaphore_t sem = dispatch_semaphore_create(0);
//  
//  [[AppHub buildManager] fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
//    dispatch_semaphore_signal(sem);
//  }];
//  
//  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
  
//  [AppHubTestUtils stubGetBuildRouteWithJsonName:@"MockResponses/working-abc.json"];
//  [AppHubTestUtils stubS3RouteWithIpaName:@"MockBuilds/React-0.11/hello-world.zip"];
  
  NSURL *jsCodeLocation = [manager.currentBuild.bundle URLForResource:@"main" withExtension:@"jsbundle"];
//  NSURL *jsCodeLocation = [NSURL URLWithString:@"http://localhost:8081/index.ios.bundle?platform=ios"];
  
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
