//
//  AHFileSystem.h
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <Foundation/Foundation.h>

extern void AHClearCurrentBuildInformation(void);
extern BOOL AHCreateBuildDirectory(NSURL *buildDirectoryURL);
extern void AHClearAllBuildsExceptBuildID(NSString *buildID);
extern void AHClearAllBuilds(void);
