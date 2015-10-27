//
//  AppHub.h
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "AHDefines.h"
#import "AHBuild.h"
#import "AHBuildManager.h"

/**
 * The AppHub class contains static functions that handle global
 * configuration for the AppHub framework.
 */

@interface AppHub : NSObject

///---------------------
/// @name Retrieving Builds
///---------------------

/// @return A shared instance of `AHBuildManager` that can be used to access the current build.
+ (AHBuildManager *)buildManager;

///---------------------
/// @name Configuration
///---------------------

/// The applicationID used to configure the AppHub framework.
/// @param applicationID The applicationID as specified from the AppHub dashboard.
+ (void)setApplicationID:(NSString *)applicationID;

/// @return The applicationID used to configure the AppHub framework.
+ (NSString *)applicationID;

/// The level of logging that will be displayed to the Xcode console.
/// @param logLevel The level of logging that will be displayed to the Xcode console.
+ (void)setLogLevel:(AHLogLevel)logLevel;

/// @return The level of logging that will be displayed to the Xcode console.
+ (AHLogLevel)logLevel;

/// The version of the installed SDK.
+ (NSString *)SDKVersion;

///---------------------
/// @name Testing Builds
///---------------------

/**
Present a view that allows you to select between all available builds of your application.

The resulting block will be invoked on the main thread, so you can present a view from the completion block.

 
Example:
 
    [[AppHub buildManager] presentSelectorWithBuildHandler:^(AHBuild *build, NSError *error) {
        if (error || ! build) {
            // An error occurred.
        } else {
            NSURL *jsCodeLocation = [build.bundle URLForResource:@"main" withExtension:@"jsbundle"];
            // ... do something with the jsbundle, like presenting an RCTRootView
        }
     }];
 
@param viewController The view controller on which a build selector table will be presented.
@param block An AHBuildResultBlock that will be invoked upon selection of a build.
 
 */
+ (void)presentSelectorOnViewController:(UIViewController *)viewController
                       withBuildHandler:(AHBuildResultBlock)block;

@end