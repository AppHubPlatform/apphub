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
    NSArray *_buildSections;
    NSDateFormatter *_dateFormatter;
    AHBuildResultBlock _resultsHandler;
}

- (instancetype)initWithBuildsResultsHandler:(AHBuildResultBlock)block
{
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        _resultsHandler = block;
        _buildSections = @[];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
    [self fetchBuilds];
}

- (void)fetchBuilds
{
    NSString *applicationID = [AppHub applicationID];
    NSString *requestString = [NSString stringWithFormat:@"%@/projects/%@/list-builds?sdk_version=%@", [AppHub rootURL], applicationID, [AppHub SDKVersion]];
    NSURL *requestURL = [NSURL URLWithString:requestString];

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:requestURL completionHandler:^(NSData *data, NSURLResponse *response, NSError * error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                AHLog(AHLogLevelError, @"Error fetching builds: %@", error);
                return;
            }
            
            NSDictionary *listBuildsJson = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            _buildSections = [self createBuildList: listBuildsJson[@"data"]];
            
            [self.tableView reloadData];
        });
    }];
    [task resume];
}

- (NSArray *)createBuildList:(NSArray *)builds
{
    NSMutableArray *sections = [NSMutableArray array];

    NSSortDescriptor *createdSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:NO];
    NSArray *sortedBuilds = [builds sortedArrayUsingDescriptors:@[createdSortDescriptor]];
    [sections addObject:sortedBuilds];

    [sections addObject:@[
    @{
        AHBuildDataNameKey: @"Local Build",
        AHBuildDataDescriptionKey: @"This build is loaded locally from the device."
    }
    ]];
    return [sections copy];
}


- (NSDictionary *)buildAtIndexPath:(NSIndexPath *)path
{
    return _buildSections[path.section][path.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *const BuildCellIdentifier = @"BuildCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:BuildCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:BuildCellIdentifier];
    }
    
    NSDictionary *item = [self buildAtIndexPath:indexPath];
    NSString *createdTime = item[AHBuildDataCreatedAtKey];
    NSDate *createdDate = createdTime ? [NSDate dateWithTimeIntervalSince1970:createdTime.doubleValue / 1000.0] : [NSDate date];

    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateStyle = NSDateFormatterShortStyle;
        _dateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    NSString *createdString = [_dateFormatter stringFromDate:createdDate];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", item[AHBuildDataNameKey], createdString];
    NSString *subtitle = [[item[AHBuildDataCompatibleIOSVersionsKey] allValues] componentsJoinedByString:@", "];
    cell.detailTextLabel.text = subtitle ?: item[AHBuildDataDescriptionKey];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section + 1 == _buildSections.count) {
        // Return the default build.
        AHBuild *defaultBuild = [[AHBuild alloc] initWithBundle:[NSBundle mainBundle] info:nil];
        _resultsHandler(defaultBuild, nil);
        return;
    }
    
    NSDictionary *buildJSON = [self buildAtIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[AppHub buildManager] downloadFromJSON:buildJSON resultsHandler:_resultsHandler];
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return (section + 1 == _buildSections.count) ? @"Local Build" : @"AppHub Builds";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return [_buildSections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_buildSections[section] count];
}

@end
