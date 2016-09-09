//
//  AHBuildManager.m
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import "AHBuildManager.h"

#import <UIKit/UIKit.h>

#import "AHDefines.h"
#import "AHBuild.h"
#import "AHBuild+Private.h"
#import "AppHub+Private.h"
#import "AHBuildManager+Private.h"
#import "AHBuildsListViewController.h"
#import "AHConstants.h"
#import "AHFileSystem.h"
#import "AHLogging.h"
#import "AHPaths.h"
#import "AHReachability.h"
#import "AH_SSZipArchive.h"

static NSError *AHError(NSString *message, ...) NS_FORMAT_FUNCTION(1, 2);

NSString *const AHBuildManagerDidMakeBuildAvailableNotification = @"AppHub.newBuild";
NSString *const AHBuildManagerBuildKey = @"AHNewBuildKey";

@implementation AHBuildManager

+ (AHBuildManager *)sharedManager
{
    static AHBuildManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[AHBuildManager alloc] _init];
    });

    return sharedManager;
}

- (instancetype)_init __attribute__((objc_method_family(init)))
{
    if ((self = [super init])) {
        self.automaticPollingEnabled = YES;
        self.cellularDownloadsEnabled = NO;
        self.debugBuildsEnabled = NO;
        self.completionHandlers = [[NSMutableArray alloc] init];
        
        [self cleanBuilds];
    }
    
    return self;
}

- (NSString *)installedAppVersion
{
    if (_installedAppVersion) { return _installedAppVersion; }

    NSBundle *mainBundle = [NSBundle mainBundle];
    return mainBundle.infoDictionary[@"CFBundleShortVersionString"];
}

- (void)cleanBuilds
{
    AHBuild *currentBuild = self.currentBuild;
    
    // Check if our current build info is old, and if it is, wipe our current build info.
    if (!currentBuild.isDefaultBuild &&
        ![currentBuild.compatibleIOSVersions containsObject:[self installedAppVersion]]) {
        AHClearAllBuilds();
    }
    
    // Clear all of the builds except for our current build.
    AHClearAllBuildsExceptBuildID(currentBuild.identifier);
}

- (NSDictionary *)currentBuildInfo
{
    return [NSDictionary dictionaryWithContentsOfURL:AHCurrentBuildInfoDirectory()];
}

- (AHBuild *)currentBuild
{
    NSDictionary *currentBuildInfo = [self currentBuildInfo];
    
    NSBundle *bundle;
    if (currentBuildInfo) {
        NSURL *currentBundleDirectory = AHBundleDirectory(currentBuildInfo[AHBuildDataBuildIDKey]);
        bundle = [NSBundle bundleWithURL:currentBundleDirectory];
    } else {
        bundle = [NSBundle mainBundle];
    }
    
    return [[AHBuild alloc] initWithBundle:bundle info:currentBuildInfo];
}

- (void)downloadFromJSON:(NSDictionary *)buildJSON resultsHandler:(AHBuildResultBlock)completion
{
    NSParameterAssert(completion != nil);
    
    AHLog(AHLogLevelDebug, @"Building... %@", buildJSON);
    
    NSArray *keys = @[
        AHBuildDataS3URLKey,
        AHBuildDataBuildIDKey,
        AHBuildDataNameKey,
        AHBuildDataDescriptionKey,
        AHBuildDataCreatedAtKey,
        AHBuildDataCompatibleIOSVersionsKey,
    ];
    
    for (NSString *key in keys) {
        if (!buildJSON[key]) {
            completion(nil, AHError(@"Missing key: %@", key));
            return;
        }
    }
    
    NSString *S3URLString = buildJSON[AHBuildDataS3URLKey];
    NSString *buildID = buildJSON[AHBuildDataBuildIDKey];
    NSString *appID = buildJSON[AHBuildDataProjectIDKey];
    NSArray *compatibleVersions = [buildJSON[AHBuildDataCompatibleIOSVersionsKey] allValues];

    // Check if our current build is the same as the build from the server.
    if ([self.currentBuild.identifier isEqualToString:buildID]) {
        AHLog(AHLogLevelDebug, @"Already downloaded build with build ID %@", buildID);
        
        // In this case, we want to return the most up-to-date build.
        completion(self.currentBuild, nil);
        return;
    }
    
    // Ensure that the appIds match
    if (![appID isEqualToString:[AppHub applicationID]]) {
        completion(nil, AHError(@"Application id from AppHub: %@ differs from expected: %@", appID, [AppHub applicationID]));
        return;
    }
    
    if (![compatibleVersions containsObject:[self installedAppVersion]]) {
        completion(nil, AHError(@"Current version of app (%@) differs from versions in downloaded build: %@", [self installedAppVersion], compatibleVersions));
        return;
    }
    
    // The directory where the newly downloaded file will live.
    NSURL *buildDirectory = AHBuildDirectory(buildID);
    if (!AHCreateBuildDirectory(buildDirectory)) {
        completion(nil, AHError(@"Could not create build directory (location %@)", buildDirectory.path));
        return;
    }
    
    AHLog(AHLogLevelDebug, @"Downloading from S3 URL: %@", S3URLString);
    NSURL *S3URL = [NSURL URLWithString:S3URLString];
    NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:S3URL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            completion(nil, AHError(@"Error fetching AppHub build from S3: %@", error.localizedDescription));
            return;
        }

        [AH_SSZipArchive unzipFileAtPath:location.path toDestination:buildDirectory.path];

        NSURL *bundleDirectory = AHBundleDirectory(buildID);
        if ([[NSFileManager defaultManager] fileExistsAtPath:bundleDirectory.path]) {
            NSURL *currentBuildInfoDirectory = AHCurrentBuildInfoDirectory();
            AHLog(AHLogLevelDebug, @"Writing new buildData (%@) to path (%@)", buildJSON, currentBuildInfoDirectory.path);
            [buildJSON writeToURL:currentBuildInfoDirectory atomically:YES];

            AHBuild *build = self.currentBuild;
            
            [[NSNotificationCenter defaultCenter] postNotificationName:AHBuildManagerDidMakeBuildAvailableNotification object:self userInfo:@{AHBuildManagerBuildKey: build}];
            
            completion(build, nil);
        } else {
            completion(nil, AHError(@"Build does not contain bundle at path: %@", bundleDirectory.path));
        }
    }];
    if (self.taskHandlerBlock) {
        self.taskHandlerBlock(task);
    }
    [task resume];
}

- (void)downloadBuildInfoWithCompletionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))handler
{
    // Check whether there's a new build to download and get the current build data from the server.
    NSString *appVersion = [self installedAppVersion];
    
#if TARGET_IPHONE_SIMULATOR
    NSString *deviceID = @"SIMULATOR";
#else
    NSString *deviceID = [UIDevice currentDevice].identifierForVendor.UUIDString;
#endif
    
    NSString *getBuildRequestString = [NSString stringWithFormat:@"%@/projects/%@/build?sdk_version=%@&app_version=%@&device_uid=%@&debug=%d", [AppHub rootURL], [AppHub applicationID], AHSDKVersion, appVersion, deviceID, _debugBuildsEnabled];

    AHLog(AHLogLevelDebug, @"Downloading build information from URL: %@", getBuildRequestString);

    NSURL *getBuildRequestURL = [NSURL URLWithString:getBuildRequestString];
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:getBuildRequestURL completionHandler:handler];
    [task resume];
}

- (NSDictionary *)_getBuildJsonFromResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError **)error
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    
    // It returns a JSON for a new build.
    NSDictionary *buildJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    NSString *status = buildJSON[AHServerStatusKey];
    if (!status || [status isEqualToString:AHServerResponseErrorType]) {
        NSString *errorString;
        switch (httpResponse.statusCode) {
            case 440:
                errorString = [NSString stringWithFormat:@"No project found with application ID \"%@\". Make sure to call: [AppHub buildManager].applicationID = @\"your application id\"", [AppHub applicationID]];
                break;
            
            case 441:
                errorString = [NSString stringWithFormat:@"It looks like your version of the SDK is out of date (%@). Go to https://apphub.io/downloads to install a newer version of the SDK.", [AppHub SDKVersion]];
                break;
                
            default:
                errorString = [NSString stringWithFormat:@"Unknown error: %@", buildJSON];
                break;
        }
        
        AHLog(AHLogLevelError, @"%@", errorString);
        if (error) {
            *error = AHError(@"%@", errorString);
        }
        return nil;
    }
    
    if (![status isEqualToString:AHServerResponseSuccessType]) {
        NSString *errorString = [NSString stringWithFormat:@"Unknown status type: %@", status];
        AHLog(AHLogLevelError, @"%@", errorString);
        if (error) {
            *error = AHError(@"%@", errorString);
        }
        return nil;
    }
    
    NSDictionary *buildData = buildJSON[AHBuildDataKey];
    NSString *buildDataType = buildData[AHBuildDataTypeKey];
    
    if ([buildDataType isEqualToString:AHBuildDataTypeGetBuild]) {
        return buildData;
    } else if ([buildDataType isEqualToString:AHBuildDataTypeNoBuild]) {
        AHLog(AHLogLevelDebug, @"Clearing current build to initialize from default bundle.");
        AHClearCurrentBuildInformation();
        return nil;
    } else {
        NSString *errorString = [NSString stringWithFormat:@"Unknown build type: %@", buildDataType];
        AHLog(AHLogLevelError, @"%@", errorString);
        if (error) {
            *error = AHError(@"%@", errorString);
        }
        return nil;
    }
}

- (void)_fetchBuildWithCompletionHandler:(AHBuildResultBlock)completionHandler
{
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        if (completionHandler) {
            completionHandler(self.currentBuild, nil);
        }
        return;
    }
    
    AHBuild *cachedBuild = self.currentBuild;
    
    if (! [AppHub applicationID]) {
        NSString *errorString = @"No AppHub application id found. Make sure to call [AppHub setApplicationId:].";
        AHLog(AHLogLevelError, @"%@", errorString);
        if (completionHandler) {
            completionHandler(nil, AHError(@"%@", errorString));
        }
        return;
    }

    [self downloadBuildInfoWithCompletionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            AHLog(AHLogLevelError, @"Error fetching AppHub build information: %@", error.localizedDescription);
            if (completionHandler) {
                completionHandler(nil, error);
            }

            return;
        }
        
        NSDictionary *buildJSON = [self _getBuildJsonFromResponse:response data:data error:&error];
        if (error) {
            AHLog(AHLogLevelError, @"%@", error.localizedDescription);
            if (completionHandler) {
                completionHandler(nil, error);
            }

            return;
        } else if (!buildJSON) {
            // In the case where we have no error, but there is no buildJson either. (No new builds)
            if (! [cachedBuild isDefaultBuild]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:AHBuildManagerDidMakeBuildAvailableNotification object:self userInfo:@{AHBuildManagerBuildKey: self.currentBuild}];
            }
            
            if (completionHandler) {
                completionHandler(self.currentBuild, nil);
            }
            
            return;
        }

        [self downloadFromJSON:buildJSON resultsHandler:^(AHBuild *result, NSError *error) {
            if (error) {
                AHLog(AHLogLevelError, @"%@", error.localizedDescription);
            }
            
            if (completionHandler) {
                completionHandler(result, error);
            }
        }];
    }];
}

- (void)fetchBuildWithCompletionHandler:(AHBuildResultBlock)completionHandler {
    if (completionHandler) {
        [self.completionHandlers addObject:completionHandler];
    }
    
    if (self.fetchingBuild) {
        return;
    }
    
    self.fetchingBuild = YES;
    
    __weak typeof(self) weakSelf = self;
    [self _fetchBuildWithCompletionHandler:^(AHBuild *result, NSError *error) {
        weakSelf.fetchingBuild = NO;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *handlers = [NSMutableArray arrayWithArray:self.completionHandlers];
            [self.completionHandlers removeAllObjects];
            
            // AHBuildManager properties are only accessible on the main thread.
            for (AHBuildResultBlock completion in handlers) {
                completion(result, error);
            }
        });
    }];
}

- (void)pollForBuilds
{
    AHReachability *reachability = [[AppHub sharedManager] reachability];
    
    if (([reachability isReachableViaWiFi] || ([reachability isReachableViaWWAN] && _cellularDownloadsEnabled)) &&
        [AppHub applicationID]) {
        [self fetchBuildWithCompletionHandler:nil];
    }
}

+ (NSSet *)keyPathsForValuesAffectingAutomaticPollingEnabled
{
    return [NSSet setWithObject:@"pollingTimer"];
}

- (BOOL)isAutomaticPollingEnabled
{
    return self.pollingTimer != nil;
}

- (void)setAutomaticPollingEnabled:(BOOL)automaticPollingEnabled
{
    if (automaticPollingEnabled == self.automaticPollingEnabled) {
        return;
    }
    
    if (automaticPollingEnabled) {
        __weak typeof(self) weakSelf = self;
        NSTimer *pollingTimer = (__bridge_transfer NSTimer *)CFRunLoopTimerCreateWithHandler(NULL, CFAbsoluteTimeGetCurrent(), 10.0, 0, 0, ^(CFRunLoopTimerRef timer) {
            [weakSelf pollForBuilds];
        });
        [[NSRunLoop currentRunLoop] addTimer:pollingTimer forMode:NSRunLoopCommonModes];
        self.pollingTimer = pollingTimer;
    } else {
        [self.pollingTimer invalidate];
        self.pollingTimer = nil;
    }
}

@end

static NSError *AHError(NSString *message, ...)
{
    va_list args;
    va_start(args, message);
    NSString *description = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);

    return [NSError errorWithDomain:@"AppHub" code:-1 userInfo:@{NSLocalizedDescriptionKey: description}];
}
