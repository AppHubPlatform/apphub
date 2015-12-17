//
//  AppHub.m
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import "AppHub.h"

#import "AppHub+Private.h"
#import "AHBuild.h"
#import "AHBuild+Private.h"
#import "AHFileSystem.h"
#import "AHBuildManager.h"
#import "AHBuildManager+Private.h"
#import "AHConstants.h"
#import "AHReachability.h"

@implementation AppHub

+ (AppHub *)sharedManager
{
    static AppHub *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[AppHub alloc] _init];
    });
    
    return sharedManager;
}

- (instancetype)_init __attribute__((objc_method_family(init)))
{
    if ((self = [super init])) {
        self.logLevel = AHLogLevelError;
        
        self.reachability = [AHReachability reachabilityWithHostname:@"www.google.com"];
        [self.reachability startNotifier];
    }
    
    return self;
}

+ (AHBuildManager *)buildManager {
    return [AHBuildManager sharedManager];
}

+ (void)setApplicationID:(NSString *)applicationID {
    [AppHub sharedManager].applicationID = applicationID;
}

+ (NSString *)applicationID {
    return [AppHub sharedManager].applicationID;
}

+ (void)setLogLevel:(AHLogLevel)logLevel {
    [AppHub sharedManager].logLevel = logLevel;
}

+ (AHLogLevel)logLevel {
    return [AppHub sharedManager].logLevel;
}

+ (NSString *)SDKVersion
{
    return AHSDKVersion;
}

@end