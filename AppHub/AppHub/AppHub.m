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
#import "AHBuildsListViewController.h"
#import "AHConstants.h"
#import "AHReachability.h"

// NSString *const AHEndpoint = @"http://apphub-staging.herokuapp.com/v1";
NSString *const AHEndpoint = @"https://api.apphub.io/v1";

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
        self.rootURL = AHEndpoint;
        
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

+ (void)setRootURL:(NSString *)rootURL {
    [AppHub sharedManager].rootURL = rootURL;
}

+ (NSString *)rootURL {
    return [AppHub sharedManager].rootURL;
}

+ (void)setLogLevel:(AHLogLevel)logLevel {
    [AppHub sharedManager].logLevel = logLevel;
}

+ (AHLogLevel)logLevel {
    return [AppHub sharedManager].logLevel;
}

+ (void)presentSelectorOnViewController:(UIViewController *)viewController
                       withBuildHandler:(AHBuildResultBlock)block;
{
    // Clear all the builds so that we don't incorrectly cache something.
    AHClearAllBuilds();
    
    AHBuildResultBlock completion = ^(AHBuild *build, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [viewController dismissViewControllerAnimated:NO completion:^{
                block(build, error);
            }];
        });
    };
    
    AHBuildsListViewController *listViewController = [[AHBuildsListViewController alloc] initWithBuildsResultsHandler:completion];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [viewController presentViewController:listViewController animated:NO completion:nil];
    });
}

+ (NSString *)SDKVersion
{
    return AHSDKVersion;
}

@end