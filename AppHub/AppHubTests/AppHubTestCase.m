//
//  AppHubTestCase.m
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import "AppHubTestCase.h"

#import <AppHub/AppHub.h>
#import <AppHubTestUtils/AppHubTestUtils.h>
#import <OCMock/OCMock.h>

#import "AHBuildManager+Private.h"
#import "AHFileSystem.h"
#import "AHLogging.h"

@implementation AppHubTestCase

-(void) setUp {
    [super setUp];

    self.mockNSBundle = [OCMockObject niceMockForClass:[NSBundle class]];
    NSBundle *correctMainBundle = [NSBundle bundleForClass:self.class];
    [[[[self.mockNSBundle stub] classMethod] andReturn:correctMainBundle] mainBundle];
    
    AHClearAllBuilds();
    AHClearLogs();
    
    [AppHub buildManager].cellularDownloadsEnabled = NO;
    [AppHub buildManager].debugBuildsEnabled = NO;
    [AppHub buildManager].automaticPollingEnabled = NO;
    [AppHub setApplicationID:@"123"];
}

-(void) tearDown {
    [AppHubTestUtils tearDown];

    [super tearDown];
}

@end
