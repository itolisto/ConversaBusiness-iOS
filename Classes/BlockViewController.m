//
//  BlockViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 3/1/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "BlockViewController.h"

@import YapDatabase;
#import "Constants.h"
#import "YapContact.h"
#import "DatabaseView.h"
#import "DatabaseManager.h"
#import "CustomBlockCell.h"
#import <YapDatabase/YapDatabaseView.h>

#define kYapDatabaseRangeLength     25
#define kYapDatabaseRangeMaxLength  300
#define kYapDatabaseRangeMinLength  20

@interface BlockViewController ()

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *blockedMappings;

@property(nonatomic) BOOL visible;

@end

@implementation BlockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Freeze our connection for use on the main-thread.
    // This gives us a stable data-source that won't change until we tell it to.
    self.databaseConnection      = [[DatabaseManager sharedInstance] newConnection];
    self.databaseConnection.name = NSStringFromClass([self class]);
    
    [self.databaseConnection beginLongLivedReadTransaction];
    
    self.blockedMappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^BOOL(NSString * _Nonnull group, YapDatabaseReadTransaction * _Nonnull transaction) {
        return YES;
    } sortBlock:^NSComparisonResult(NSString * _Nonnull group1, NSString * _Nonnull group2, YapDatabaseReadTransaction * _Nonnull transaction) {
        return NSOrderedSame;
    } view:BlockedDatabaseViewExtensionName];
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.blockedMappings updateWithTransaction:transaction];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:[DatabaseManager sharedInstance].database];
    
    // Remove extra lines
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:v];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.visible = YES;
    [self.tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.visible = NO;
}

#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

#pragma mark - UITableViewDataSource Methods -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.blockedMappings numberOfItemsInSection:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.blockedMappings numberOfSections];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *simpleTableIdentifier = @"CustomBlockCell";
    CustomBlockCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[CustomBlockCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    YapContact *contact = [self blockAtIndexPath:indexPath];
    
    [cell configureCellWith:contact];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        YapContact *contact = [self blockAtIndexPath:indexPath];
        
        [contact programActionInHours:0 isMuting:NO];
            
        [[DatabaseManager sharedInstance].newConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            // Update contact
            contact.blocked = NO;
            [contact saveWithTransaction:transaction];
        } completionBlock:^{
            //[[PubNubService sharedInstance] subscribeToChannels:@[[contact getPrivateChannel]]];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:BLOCK_NOTIFICATION_NAME
                                                                object:nil
                                                              userInfo:nil];
        }];
    }
}

#pragma mark - YapDatabase Methods -

- (YapContact *)blockAtIndexPath:(NSIndexPath *)indexPath {
    __block YapContact *block = nil;
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        YapDatabaseViewTransaction *viewTransaction = [transaction ext:BlockedDatabaseViewExtensionName];
        NSUInteger row = indexPath.row;
        NSUInteger section = indexPath.section;
        
        NSAssert(row < [self.blockedMappings numberOfItemsInSection:section], @"Cannot fetch block user because row %d is >= numberOfItemsInSection %d", (int)row, (int)[self.blockedMappings numberOfItemsInSection:section]);
        
        block = [viewTransaction objectAtRow:row inSection:section withMappings:self.blockedMappings];
        NSParameterAssert(block != nil);
    }];
    
    return block;
}

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Jump to the most recent commit.
    // End & Re-Begin the long-lived transaction atomically.
    // Also grab all the notifications for all the commits that I jump.
    // If the UI is a bit backed up, I may jump multiple commits.
    NSArray *notifications  = [self.databaseConnection beginLongLivedReadTransaction];
    
    if ([notifications count] <= 0) {
        // Since we moved our databaseConnection to a new commit,
        // we need to update the mappings too.
        [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [self.blockedMappings updateWithTransaction:transaction];
        }];
        return; // Already processed commit
    }
    
    // If the view isn't visible, we might decide to skip the UI animation stuff.
    if (!self.visible) {
        [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction){
            [self.blockedMappings updateWithTransaction:transaction];
        }];
        return;
    }
    
    NSArray *rowChanges = nil;
    
    [[self.databaseConnection ext:BlockedDatabaseViewExtensionName] getSectionChanges:NULL
                                                                           rowChanges:&rowChanges
                                                                     forNotifications:notifications
                                                                         withMappings:self.blockedMappings];
    
    if ([rowChanges count] == 0) {
        // Nothing has changed that affects our tableView
        return;
    }
    
    // Familiar with NSFetchedResultsController?
    // Then this should look pretty familiar
    
    [self.tableView beginUpdates];
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges) {
        switch (rowChange.type) {
            case YapDatabaseViewChangeDelete : {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert : {
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove : {
                [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate : {
                [self.tableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.tableView endUpdates];
}

@end