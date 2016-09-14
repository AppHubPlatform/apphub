//
//  AHBuildManager+Private.h
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import "AHBuildManager.h"

@interface AHBuildManager ()

@property (nonatomic, getter=isFetchingBuild) BOOL fetchingBuild;
@property (nonatomic, readonly, strong) NSMutableString *logs;
@property (nonatomic, strong) NSTimer *pollingTimer;
@property (nonatomic, strong) NSMutableArray *completionHandlers;

+ (AHBuildManager *)sharedManager;

- (void)cleanBuilds;
- (void)downloadFromJSON:(NSDictionary *)buildJSON resultsHandler:(AHBuildResultBlock)completion;

@end
