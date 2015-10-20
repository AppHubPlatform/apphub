//
//  AHBuildTests.m
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AppHub/AppHub.h>
#import <AppHubTestUtils/AppHubTestUtils.h>

#import <OCMock/OCMock.h>
#import <asl.h>
#import "AHBuild+Private.h"

#import "AppHubTestCase.h"

@interface AHBuildTests : AppHubTestCase

@end

@implementation AHBuildTests

- (void)testDefaultBuilds {
    AHBuild *buildOne = [[AHBuild alloc] init];
    AHBuild *buildTwo = [[AHBuild alloc] initWithBundle:[NSBundle mainBundle] info:nil];
    
    for (AHBuild *build in @[buildOne, buildTwo]) {
        XCTAssertTrue(build.isDefaultBuild);
        XCTAssertNotNil(build.name);
        XCTAssertNotNil(build.buildDescription);
        XCTAssertNotNil(build.compatibleIOSVersions);
        XCTAssertNotNil(build.creationDate);
        XCTAssertEqualObjects(build.identifier, @"LOCAL");
        XCTAssertEqualObjects(build.bundle, [NSBundle mainBundle]);
    }
}

@end