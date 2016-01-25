//
//  AppHubReactModule.m
//  AppHub
//
//  Created by Matthew Arbesfeld on 8/16/15.
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RCTBridgeModule.h"
#import "RCTDefines.h"
#import "RCTEventDispatcher.h"

#import "AppHub.h"
#import "AHBuild+Private.h"
#import "AHBuildManager.h"
#import "AHDefines.h"

@interface AppHubReactModule : NSObject <RCTBridgeModule>
@end

@implementation AppHubReactModule

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE(AppHub)

- (instancetype)init
{
    if ((self = [super init])) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(buildManagerDidMakeBuildAvailable:) name:AHBuildManagerDidMakeBuildAvailableNotification object:nil];
    }
    
    return self;
}

- (void)buildManagerDidMakeBuildAvailable:(NSNotification *)notification
{
    AHBuild *build = notification.userInfo[AHBuildManagerBuildKey];
    [_bridge.eventDispatcher sendAppEventWithName:AHBuildManagerDidMakeBuildAvailableNotification
                                             body:build.dictionaryValue];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSDictionary *)constantsToExport
{
    return [AppHub buildManager].currentBuild.dictionaryValue;
}

@end