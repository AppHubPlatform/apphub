//
//  AppHub+Private.h
//  AppHub
//
//  Created by Matthew Arbesfeld on 8/15/15.
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import "AppHub.h"
#import "AHDefines.h"

@class AHReachability;

@interface AppHub ()

+ (AppHub *)sharedManager;

// The applicationID used to configure the AppHub framework.
@property (nonatomic, copy) NSString *applicationID;

// The level of logging that will be displayed to the Xcode console.
@property (nonatomic, assign) AHLogLevel logLevel;

@property (nonatomic, strong) AHReachability *reachability;

@end