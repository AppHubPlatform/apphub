//
//  AHLogging.m
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import "AppHub.h"
#import "AHLogging.h"
#import "AHBuildManager.h"

static NSMutableString *logs;

void AHLog(AHLogLevel logLevel, NSString *message, ...)
{
    if (logLevel > [AppHub logLevel]) {
        return;
    }

    va_list args;
    va_start(args, message);
    NSString *log = [[NSString alloc] initWithFormat:message arguments:args];
    va_end(args);

    switch (logLevel) {
        case AHLogLevelError:
            log = [@"(ERROR) " stringByAppendingString:log];
            break;
        case AHLogLevelWarning:
            log = [@"(WARNING) " stringByAppendingString:log];
            break;
        default:
            break;
    }

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logs = [NSMutableString string];
    });

    NSLog(@"AppHub: %@", log);
    [logs appendString:log];
    [logs appendString:@"\n"];
}

void AHClearLogs(void)
{
    logs = [NSMutableString string];
}

extern NSString *AHLogs(void)
{
    return logs ?: @"";
}
