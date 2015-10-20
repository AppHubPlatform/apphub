//
//  AHConstants.h
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

extern NSString *const AHAssetBundleName;

extern NSString *const AHBuildDataKey;
extern NSString *const AHBuildDataBuildIDKey;
extern NSString *const AHBuildDataNameKey;
extern NSString *const AHBuildDataDescriptionKey;
extern NSString *const AHBuildDataCreatedAtKey;
extern NSString *const AHBuildDataProjectIDKey;
extern NSString *const AHBuildDataS3URLKey;
extern NSString *const AHBuildDataCompatibleIOSVersionsKey;

extern NSString *const AHBuildDataTypeGetBuild;
extern NSString *const AHBuildDataTypeKey;
extern NSString *const AHBuildDataTypeNoBuild;
extern NSString *const AHBuildDirectoryName;
extern NSString *const AHCurrentBuildInfoName;

extern NSString *const AHDirectoryName;
extern NSString *const AHEndpoint;
extern NSString *const AHIOSBundleName;
extern NSString *const AHNewBuildEvent;
extern NSString *const AHSDKVersion;
extern NSString *const AHServerResponseErrorType;
extern NSString *const AHServerResponseSuccessType;
extern NSString *const AHServerStatusKey;

extern NSString *const AHExportedBuildDataBuildIDKey;
extern NSString *const AHExportedBuildDataNameKey;
extern NSString *const AHExportedBuildDataDescriptionKey;
extern NSString *const AHExportedBuildDataCreatedAtKey;
extern NSString *const AHExportedBuildDataCompatibleIOSVersionsKey;