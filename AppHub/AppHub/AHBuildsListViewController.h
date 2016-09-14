//
//  AHBuildsListViewController.h
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AHDefines.h"

@interface AHBuildsListViewController : UITableViewController


- (instancetype)initWithBuildsResultsHandler:(AHBuildResultBlock)block;

@end
