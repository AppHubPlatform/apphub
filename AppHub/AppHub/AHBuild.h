//
//  AHBuild.h
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
An object that represents an AppHub build. This object
holds a reference to an `NSBundle` which contains `.jsbundle` files
and images for a build. An AHBuild also contains build metadata, such
as an identifier and description.

Example usage:

    AHBuild *build = [AppHub buildManager].currentBuild;
    NSURL *jsCodeLocation = [build.bundle URLForResource:@"main" withExtension:@"jsbundle];

 */

@interface AHBuild : NSObject

///---------------------
/// @name Properties
///---------------------

/**
 * The bundle of JavaScript and images for a build of your application. Use
 * `-[NSBundle URLForResource:withExtension:]` and other `NSBundle` methods to
 * access files within the bundle.
 */
@property (nonatomic, readonly) NSBundle *bundle;

/// The identifier, or `LOCAL` if the build originates from the App Store.
/// This identifier is guaranteed to be unique for each build of your app.
@property (nonatomic, readonly) NSString *identifier;

/**
 * The name of the build as defined form the AppHub dashboard.
 */
@property (nonatomic, readonly) NSString *name;

/**
 * The user-defined description of the build. Build descriptions can be
 * configured from the AppHub dashboard.
 */
@property (nonatomic, readonly) NSString *buildDescription;

/// The date at which the build was created.
@property (nonatomic, readonly) NSDate *creationDate;

/// An array of iOS app version strings with which the build is compatible.
@property (nonatomic, readonly) NSArray *compatibleIOSVersions;

@end
