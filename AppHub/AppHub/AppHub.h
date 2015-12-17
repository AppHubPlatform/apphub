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

@end