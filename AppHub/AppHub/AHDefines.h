//
//  AHDefines.h
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AHBuild;

/// A block that is a called from the result of an asynchronous AHBuild request.
typedef void (^AHBuildResultBlock)(AHBuild *result, NSError *error);

/// The identifier for an AHBuild that originates from the App Store.
extern NSString *const AHDefaultBuildID;

/**
 * Specifies different logging levels for limiting log message display.
 *
 * @see [AppHub setLogLevel:]
 */
typedef NS_ENUM(NSUInteger, AHLogLevel) {
    /// Disables all logging.
    AHLogLevelNone,

    /// Displays only AHLogLevelError logs.
    AHLogLevelError,

    /// Displays AHLogLevelError and AHLogLevelWarning logs.
    AHLogLevelWarning,

    /// Displays AHLogLevelError, AHLogLevelWarning, and AHLogLevelDebug logs.
    AHLogLevelDebug,
};
