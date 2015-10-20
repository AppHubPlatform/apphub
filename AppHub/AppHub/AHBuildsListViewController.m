//
//  AHBuildsListViewController.m
//  AppHub
//
//  Copyright (c) 2015 AppHub. All rights reserved.
//

#import "AHBuildsListViewController.h"

#import "AppHub.h"
#import "AHBuild.h"
#import "AHBuild+Private.h"
#import "AHBuildManager.h"
#import "AHBuildManager+Private.h"
#import "AHConstants.h"
#import "AHLogging.h"

@implementation AHBuildsListViewController
{
    NSArray *_builds;
    NSDateFormatter *_dateFormatter;
    AHBuildResultBlock _resultsHandler;
}

- (instancetype)initWithBuildsResultsHandler:(AHBuildResultBlock)block
{
    if ((self = [super initWithStyle:UITableViewStylePlain])) {
        _resultsHandler = block;
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self fetchBuilds];
}

- (void)fetchBuilds
{
    NSString *applicationID = [AppHub applicationID];
    NSString *requestString = [NSString stringWithFormat:@"%@/projects/%@/list-builds?sdk_version=%@", AHEndpoint, applicationID, [AppHub SDKVersion]];
    NSURL *requestURL = [NSURL URLWithString:requestString];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:requestURL completionHandler:^(NSData *data, NSURLResponse *response, NSError * error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                AHLog(AHLogLevelError, @"Error fetching builds: %@", error);
                return;
            }
            
            NSDictionary *listBuildsJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            _builds = [listBuildsJson[@"data"] arrayByAddingObject:@{
                 AHBuildDataNameKey: @"Local Build",
                 AHBuildDataDescriptionKey: @"This build is loaded locally from the device."
             }];
            
            [self.tableView reloadData];
        });
    }];
    [task resume];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *const BuildCellIdentifier = @"BuildCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BuildCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:BuildCellIdentifier];
    }
    
    NSDictionary *item = _builds[indexPath.row];
    NSString *createdTime = item[AHBuildDataCreatedAtKey];
    NSDate *createdDate = createdTime ? [NSDate dateWithTimeIntervalSince1970:createdTime.doubleValue / 1000.0] : [NSDate date];

    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    NSString *createdString = [_dateFormatter stringFromDate:createdDate];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", item[AHBuildDataNameKey], createdString];
    cell.detailTextLabel.text = item[AHBuildDataDescriptionKey];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row + 1 == _builds.count) {
        // Return the default build.
        AHBuild *defaultBuild = [[AHBuild alloc] initWithBundle:[NSBundle mainBundle] info:nil];
        _resultsHandler(defaultBuild, nil);
        return;
    }
    
    NSDictionary *buildJSON = _builds[indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[AppHub buildManager] downloadFromJSON:buildJSON resultsHandler:_resultsHandler];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_builds count];
}

@end
