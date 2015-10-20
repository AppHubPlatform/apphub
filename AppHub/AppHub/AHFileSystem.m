//
//  AHFileSystem.m
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import "AHFileSystem.h"

#import "AHLogging.h"
#import "AHPaths.h"

void AHClearCurrentBuildInformation(void)
{
    NSURL *currentBuildInfoDirectory = AHCurrentBuildInfoDirectory();

    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:currentBuildInfoDirectory.path] &&
        ![[NSFileManager defaultManager] removeItemAtURL:currentBuildInfoDirectory error:&error]) {
        AHLog(AHLogLevelError, @"Could not remove current build (path %@): %@", currentBuildInfoDirectory, error.localizedDescription);
    }
}

BOOL AHCreateBuildDirectory(NSURL *buildDirectoryURL)
{
    AHLog(AHLogLevelDebug, @"Creating build folder: location %@", buildDirectoryURL.path);
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:buildDirectoryURL.path]) {
        AHLog(AHLogLevelDebug, @"Build folder found, deleting it now.");

        NSError *error;
        if (![[NSFileManager defaultManager] removeItemAtURL:buildDirectoryURL error:&error]) {
            AHLog(AHLogLevelError, @"Could not remove build (location %@): %@", buildDirectoryURL.path, error);
            return NO;
        }
    }

    NSError *error;
    if (![[NSFileManager defaultManager] createDirectoryAtURL:buildDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
        AHLog(AHLogLevelError, @"Could not create build directory (location %@): %@", buildDirectoryURL.path, error);
        return NO;
    }

    // Mark the directory as excluded from iCloud backups
    [buildDirectoryURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:NULL];
    return YES;
}

void AHClearAllBuildsExceptBuildID(NSString *buildID)
{
    NSURL *buildsDirectory = AHBuildsDirectory();

    BOOL isDirectory;
    if (!([[NSFileManager defaultManager] fileExistsAtPath:buildsDirectory.path isDirectory:&isDirectory] && isDirectory)) {
        return;
    }

    const NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles;
    NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:buildsDirectory includingPropertiesForKeys:nil options:options errorHandler:nil];
    for (NSURL *fileURL in enumerator) {
        if ([fileURL.lastPathComponent isEqualToString:buildID]) {
            continue;
        }

        NSError *error;
        if (![[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error]) {
            AHLog(AHLogLevelError, @"Could not remove build folder (location %@): %@", fileURL.path, error);
        }
    }
}

void AHClearAllBuilds(void)
{
    NSURL *rootDirectory = AHRootDirectory();

    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:rootDirectory.path] &&
        ![[NSFileManager defaultManager] removeItemAtURL:rootDirectory error:&error]) {
        AHLog(AHLogLevelError, @"Could not remove current build (%@): %@", rootDirectory, error);
    }
}
