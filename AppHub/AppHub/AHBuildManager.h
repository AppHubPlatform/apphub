//
//  AHBuildManager.h
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AHDefines.h"

typedef void (^TaskHandlerBlock)(NSURLSessionDownloadTask *task);

@class AHBuild;

/**
 * Posted whenever a new build becomes available for this application. Use this
 * opportunity to notify the user of a new build, or force refresh the 
 * application.
 */
extern NSString *const AHBuildManagerDidMakeBuildAvailableNotification;

/**
 * Notification user info key for the newly available build.
 */
extern NSString *const AHBuildManagerBuildKey;

/**
 * The AHBuildManager contains methods for retrieving the current build and fetching new builds.
 *
 * Access the AHBuildManager singleton by calling `[AppHub buildManager]`.
 *
 * @see [AppHub buildManager]
 */
@interface AHBuildManager : NSObject

- (instancetype)init NS_UNAVAILABLE;

///---------------------
/// @name Retrieving Builds
///---------------------

/**
 * The currently loaded build of your application, either the remote build if it
 * has been loaded or the instance for the App Store build.
 */
@property (nonatomic, readonly) AHBuild *currentBuild;

///---------------------
/// @name Configuration
///---------------------

/**
 * Use `debugBuildsEnabled` to enable debug builds for this device. Setting this property to
 * `true` will cause your app to load builds that are designated as "debug-only" in the AppHub dashboard.
 *
 * Defaults to `false`.
 */
@property (nonatomic, assign, getter=areDebugBuildsEnabled) BOOL debugBuildsEnabled;

/**
 * The AppHub SDK will poll the server for new builds of your App. By default,
 * the SDK will only poll for new builds when the device is connected to WiFi. You can
 * configure this behavior via the `cellularDownloadsEnabled` property.
 *
 * To manually control the frequency and timing of the polling, you can disable automatic polling by 
 * setting this property to 'false'.
 *
 * See the docs for a full explanation of AppHub polling.
 *
 * Defaults to `true`.
 */
@property (nonatomic, assign, getter=isAutomaticPollingEnabled) BOOL automaticPollingEnabled;

/**
 * By default, the AppHub SDK will only poll for new builds when the device is connected to WiFi.
 *
 * Set this property to `true` to enable downloads on any internet connection. Caution: enabling this boolean
 * will increase your app's data usage.
 *
 * Defaults to `false`.
 */
@property (nonatomic, assign, getter=areCellularDownloadsEnabled) BOOL cellularDownloadsEnabled;


/**
 * By default, the AppHub SDK will use the version of your application to ensure that AppHub builds match
 * your application. If the version of your AppHub build is different to your application's then
 * you can use this setting to have AppHub look for a specific version.
 *
 * Defaults to `NSBundle mainBundle`'s CFBundleShortVersionString.
 */
@property (nonatomic, copy, readwrite) NSString *installedAppVersion;

///---------------------
/// @name Fetching Builds Manually (Advanced)
///---------------------

/**
 * Fetch a build from AppHub with a completion block. Call this method to force
 * the SDK to check for newly available builds, or use it to guarantee that you
 * load the most up-to-date JavaScript on each client.
 *
 * @param completionHandler A block of type AHBuildResultBlock that will be invoked upon
 * completion of the fetch. If not nil, the resulting `AHBuild` in the block is guaranteed to
 * be the most up-to-date build of your application.
 */
- (void)fetchBuildWithCompletionHandler:(AHBuildResultBlock)completionHandler;

/**
 * Hook called after NSURLSessionDownloadTask has created
 *
 * Useful for a handling download progress on the slow connection:
 *
 * [[AppHub buildManager] setTaskHandlerBlock:^(NSURLSessionDownloadTask *task){
 *   [progressView setProgressWithDownloadProgressOfTask:task animated:YES];
 * }];
 */
@property (nonatomic, copy) TaskHandlerBlock taskHandlerBlock;

@end
