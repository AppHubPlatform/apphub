//
//  NSURLRequest+AppHub.m
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "AppHub.h"
#import "AHConstants.h"
#import "AHBuild.h"
#import "AHBuildManager.h"

@implementation NSURLRequest (AppHub)

+ (void)load
{
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return;
    }
    
    Class class = object_getClass((id)self);
    
    SEL originalSelector = @selector(requestWithURL:);
    SEL overrideSelector = @selector(ah_requestWithURL:);
    Method originalMethod = class_getClassMethod(class, originalSelector);
    Method overrideMethod = class_getClassMethod(class, overrideSelector);
    if (class_addMethod(class, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod))) {
        class_replaceMethod(class, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, overrideMethod);
    }
}

+ (NSURLRequest *)ah_requestWithURL:(NSURL *)url
{
    AHBuild *build = [AppHub buildManager].currentBuild;
    NSString *urlStr = url.absoluteString;
    NSRange range = [urlStr rangeOfString:@"assets/"];
    if (range.location != NSNotFound && url.isFileURL) {
        NSURL *bundleUrl = [[build bundle] URLForResource:[urlStr substringFromIndex:range.location] withExtension:nil];
        if (bundleUrl) {
            return [self ah_requestWithURL:bundleUrl];
        }
    }
    
    return [self ah_requestWithURL:url];
}

@end
