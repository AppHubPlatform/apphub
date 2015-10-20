//
//  AppHubTestUtils.m
//  AppHubTestUtils
//
//  Created by Matthew Arbesfeld on 8/15/15.
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import "AppHubTestUtils.h"
#import "OHHTTPStubs.h"

@implementation AppHubTestUtils

+ (NSBundle *)frameworkBundle {
    static NSBundle* frameworkBundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString* mainBundlePath = [[NSBundle bundleForClass:self.class] bundlePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"AppHubTestBundle.bundle"];
        
        frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
        
        if (!frameworkBundle) {
            frameworkBundlePath = [[mainBundlePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"AppHubTestBundle.bundle"];
            frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
        }
    });
    return frameworkBundle;
}

+(void) stubListBuildsRoute {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] rangeOfString:@"list-builds"].location != NSNotFound;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(@"MockResponses/list-builds/builds.json", [self frameworkBundle]) statusCode:200 headers:nil];
    }];
}

// Stub the s3 route. If nil, returns an error.
+(void) stubS3RouteWithIpaName:(NSString *)ipaName url:(NSString *)url {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] rangeOfString:url].location != NSNotFound;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        if (! ipaName) {
            NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
            return [OHHTTPStubsResponse responseWithError:notConnectedError];
        }
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(ipaName, [self frameworkBundle])
                                                statusCode:200 headers:@{}];
    }];
}


+(NSDictionary *) buildInformationWithName:(NSString *)name {
    NSBundle *bundle = [self frameworkBundle];
    NSString *responsePath = [bundle pathForResource:[NSString stringWithFormat:@"MockResponses/%@", name]
                                              ofType:@"json"];
    NSData *responseData = [NSData dataWithContentsOfFile:responsePath];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:responseData
                                                         options:NSJSONReadingMutableContainers
                                                           error:nil];
    return dict[@"data"];
}

// Stub the build route. If nil, returns an error.
+(void) stubGetBuildRouteWithJsonName:(NSString *)jsonName code:(int)code {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] rangeOfString:@"/build?"].location != NSNotFound;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        if (! jsonName) {
            NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
            return [OHHTTPStubsResponse responseWithError:notConnectedError];
        }
        
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(jsonName, [self frameworkBundle])
                                                statusCode:code headers:@{@"Content-Type":@"application/json"}];
    }];
}

+(void) stubGetBuildRouteWithJsonName:(NSString *)jsonName {
    [self stubGetBuildRouteWithJsonName:jsonName code:200];
}

+(void) stubGetBuildRouteWithErrorCode:(int)code {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] rangeOfString:@"/build?"].location != NSNotFound;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        NSError* error = code == 0 ?
        [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil] :
        [NSError errorWithDomain:NSURLErrorDomain code:code userInfo:nil];
        
        return [OHHTTPStubsResponse responseWithError:error];
    }];
}

// Stub the s3 route. If nil, returns an error.
+(void) stubS3RouteWithIpaName:(NSString *)ipaName {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] rangeOfString:@"aws"].location != NSNotFound;
    } withStubResponse:^OHHTTPStubsResponse*(NSURLRequest *request) {
        if (! ipaName) {
            NSError* notConnectedError = [NSError errorWithDomain:NSURLErrorDomain code:kCFURLErrorNotConnectedToInternet userInfo:nil];
            return [OHHTTPStubsResponse responseWithError:notConnectedError];
        }
        return [OHHTTPStubsResponse responseWithFileAtPath:OHPathForFileInBundle(ipaName, [self frameworkBundle])
                                                statusCode:200 headers:@{}];
    }];
}

+(void) tearDown {
    [OHHTTPStubs removeAllStubs];
}

+(void) clearBuilds {
    NSString *appSupportDir = [[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"__AppHub__" isDirectory:YES].path;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:appSupportDir isDirectory:NULL]) {
        [[NSFileManager defaultManager] removeItemAtPath:appSupportDir error:nil];
    }
}
@end