//
//  UIImage+AppHub.m
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

@implementation UIImage (AppHub)

+ (void)load
{
    if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        return;
    }
    
    Class class = object_getClass((id)self);
    
    SEL originalSelector = @selector(imageNamed:);
    SEL overrideSelector = @selector(ah_imageNamed:);
    Method originalMethod = class_getClassMethod(class, originalSelector);
    Method overrideMethod = class_getClassMethod(class, overrideSelector);
    if (class_addMethod(class, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod))) {
        class_replaceMethod(class, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, overrideMethod);
    }
}

+ (UIImage *)ah_imageNamed:(NSString *)name
{
    AHBuild *build = [AppHub buildManager].currentBuild;
    if (build) {
        UIImage *image = [UIImage imageNamed:name inBundle:build.bundle compatibleWithTraitCollection:nil];
        if (image) {
            return image;
        }
    }

    return [self ah_imageNamed:name];
}

@end
