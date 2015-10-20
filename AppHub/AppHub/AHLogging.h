//
//  AHLogging.h
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import "AHDefines.h"

extern void AHLog(AHLogLevel logLevel, NSString *message, ...) NS_FORMAT_FUNCTION(2, 3);
extern void AHClearLogs(void);
extern NSString *AHLogs(void);
