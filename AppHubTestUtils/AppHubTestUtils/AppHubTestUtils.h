//
//  AppHubTestUtils.h
//  AppHubTestUtils
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AppHubTestUtils : NSObject

+(NSDictionary *) buildInformationWithName:(NSString *)name;

// Stub the s3 route. If nil, returns an error.
+(void) stubListBuildsRoute;

// Stub the s3 route. If nil, returns an error.
+(void) stubS3RouteWithIpaName:(NSString *)ipaName url:(NSString *)url;

// Stub the build route. If nil, returns an error.
+(void) stubGetBuildRouteWithJsonName:(NSString *)jsonName code:(int)code;

+(void) stubGetBuildRouteWithJsonName:(NSString *)jsonName;

+(void) stubGetBuildRouteWithErrorCode:(int)code;

// Stub the s3 route. If nil, returns an error.
+(void) stubS3RouteWithIpaName:(NSString *)ipaName;

+(void) tearDown;

+(void) clearBuilds;

@end
