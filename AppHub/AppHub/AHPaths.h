//
//  AHPaths.h
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSURL *AHBuildDirectory(NSString *buildID);
extern NSURL *AHBundleDirectory(NSString *buildID);
extern NSURL *AHCurrentBuildInfoDirectory(void);
extern NSURL *AHBuildsDirectory(void);
extern NSURL *AHRootDirectory(void);
