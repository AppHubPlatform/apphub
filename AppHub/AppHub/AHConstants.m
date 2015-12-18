//
//  AHConstants.m
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import "AHDefines.h"
#import "AHConstants.h"

NSString *const AHSDKVersion = @"0.3.6";

// NSString *const AHEndpoint = @"http://apphub-staging.herokuapp.com/v1";
NSString *const AHEndpoint = @"https://api.apphub.io/v1";
//NSString *const AHEndpoint = @"http://localhost:5000/v1";
// NSString *const AHEndpoint = @"http://55387d52.ngrok.io/v1";

NSString *const AHAssetBundleName = @"Assets.bundle";

NSString *const AHBuildDataKey = @"data";
NSString *const AHBuildDataBuildIDKey = @"uid";
NSString *const AHBuildDataNameKey = @"name";
NSString *const AHBuildDataDescriptionKey = @"description";
NSString *const AHBuildDataCreatedAtKey = @"created";
NSString *const AHBuildDataS3URLKey = @"s3_url";
NSString *const AHBuildDataProjectIDKey = @"project_uid";
NSString *const AHBuildDataCompatibleIOSVersionsKey = @"app_versions";

NSString *const AHBuildDataTypeGetBuild = @"GET-BUILD";
NSString *const AHBuildDataTypeKey = @"type";
NSString *const AHBuildDataTypeNoBuild = @"NO-BUILD";
NSString *const AHBuildDirectoryName = @"builds";
NSString *const AHCurrentBuildInfoName = @"current_build";
NSString *const AHDefaultBuildID = @"LOCAL";
NSString *const AHDirectoryName = @"__AppHub__";
NSString *const AHIOSBundleName = @"ios.bundle";
NSString *const AHServerResponseErrorType = @"error";
NSString *const AHServerResponseSuccessType = @"success";
NSString *const AHServerStatusKey = @"status";

// Exported keys to JavaScript
NSString *const AHExportedBuildDataBuildIDKey = @"buildIdentifier";
NSString *const AHExportedBuildDataNameKey = @"buildName";
NSString *const AHExportedBuildDataDescriptionKey = @"buildDescription";
NSString *const AHExportedBuildDataCreatedAtKey = @"buildCreatedAt";
NSString *const AHExportedBuildDataCompatibleIOSVersionsKey = @"buildCompatibleIOSVersions";
