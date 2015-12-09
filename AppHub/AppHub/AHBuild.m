//
//  AHBuild.m
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import "AHBuild.h"

#import "AHBuild+Private.h"
#import "AHConstants.h"
#import "AHDefines.h"
#import "AHLogging.h"

NS_INLINE NSString *AHShortVersionString(void)
{
    return [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
}

@implementation AHBuild
{
    NSString *_buildDescription;
    NSBundle *_bundle;
    NSDate *_creationDate;
    NSArray *_compatibleIOSVersions;
    NSString *_identifier;
    NSString *_name;
}

- (instancetype)init
{
    return [self initWithBundle:nil info:nil];
}

- (instancetype)initWithBundle:(NSBundle *)bundle info:(NSDictionary *)info
{
    if ((self = [super init])) {
        _buildDescription = [info[AHBuildDataDescriptionKey] copy] ?: @"This build was downloaded from the App Store.";
        _bundle = bundle ?: [NSBundle mainBundle];
        _compatibleIOSVersions = [info[AHBuildDataCompatibleIOSVersionsKey] allValues] ?: @[AHShortVersionString()];
        if (info[AHBuildDataCreatedAtKey]) {
            _creationDate = [NSDate dateWithTimeIntervalSince1970:[info[AHBuildDataCreatedAtKey] doubleValue] / 1000.0];
        }
        _identifier = [info[AHBuildDataBuildIDKey] copy] ?: AHDefaultBuildID;
        _name = [info[AHBuildDataNameKey] copy] ?: AHDefaultBuildID;
    }
    return self;
}

+ (NSSet *)keyPathsForValuesAffectingDefaultBuild
{
    return [NSSet setWithObject:@"identifier"];
}

- (BOOL)isDefaultBuild
{
    return self.bundle == [NSBundle mainBundle];
}

- (NSDictionary *)dictionaryValue
{
    return @{
        AHExportedBuildDataBuildIDKey: _identifier,
        AHExportedBuildDataNameKey: _name,
        AHExportedBuildDataDescriptionKey: _buildDescription,
        AHExportedBuildDataCreatedAtKey: _creationDate ? @(_creationDate.timeIntervalSince1970 * 1000.0) : [NSNull null],
        AHExportedBuildDataCompatibleIOSVersionsKey: _compatibleIOSVersions,
    };
}

@end
