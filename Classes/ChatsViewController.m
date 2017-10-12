//
//  ChatsViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 11/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "ChatsViewController.h"

@import YapDatabase;
#import "Log.h"
#import "Colors.h"
#import "AppJobs.h"
#import "Constants.h"
#import "AppDelegate.h"
#import "DatabaseView.h"
#import "SettingsKeys.h"
#import "UIStateButton.h"
#import "CustomChatCell.h"
#import "DatabaseManager.h"
#import "SettingsViewController.h"
#import "NotificationPermissions.h"
#import "ConversationViewController.h"

#import <Parse/Parse.h>
#import <QuartzCore/QuartzCore.h>
#import <YapDatabase/YapDatabaseView.h>
#import <YapDatabase/YapDatabaseSearchQueue.h>

@interface ChatsViewController ()

@property (weak, nonatomic) IBOutlet UIView *emptyView;
@property (weak, nonatomic) IBOutlet UILabel *noMessagesLine1;
@property (weak, nonatomic) IBOutlet UIStateButton *startBrowsingButton;
@property (strong, nonatomic) NSMutableArray *filteredCategories;
@property (nonatomic, strong) NSTimer *cellUpdateTimer;
@property (nonatomic, assign) CGPoint lastTableViewPosition;
@property (nonatomic, assign) BOOL searchMode;
@property (nonatomic, assign) BOOL reloadData;

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseConnection *searchConnection;
@property (nonatomic, strong) YapDatabaseConnection *muteConnection;
@property (nonatomic, strong) YapDatabaseSearchQueue *searchQueue;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseViewMappings *searchMappings;
@property (nonatomic, strong) YapDatabaseViewMappings *unreadConversationsMappings;

@end

@implementation ChatsViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    // Set Conversa logo into NavigationBar
    UIImage* logoImage = [UIImage imageNamed:@"im_logo_text_white"];
    UIImageView* view = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    view.contentMode = UIViewContentModeScaleAspectFit;
    view.image = logoImage;
    self.navigationItem.titleView = view;

    // Add border to Button
    [self.startBrowsingButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
    [self.startBrowsingButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.startBrowsingButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
    [self.startBrowsingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    // If we are using this same view controller to present the results
    // dimming it out wouldn't make sense.  Should set probably only set
    // this to yes if using another controller to display the search results.
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.showsScopeBar = NO;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = NSLocalizedString(@"chat_searchbar_placeholder", nil);
    // Sets this view controller as presenting view controller for the search interface
    self.definesPresentationContext = YES;
    // Set SearchBar into NavigationBar
    self.tableView.tableHeaderView = self.searchController.searchBar;
    [self.searchController.searchBar sizeToFit];
    // By default the navigation bar hides when presenting the
    // search interface.  Obviously we don't want this to happen if
    // our search bar is inside the navigation bar.
    self.searchController.hidesNavigationBarDuringPresentation = YES;
    
    self.noMessagesLine1.adjustsFontSizeToFitWidth = YES;
    self.noMessagesLine1.minimumScaleFactor = 1;
    
    // Load initial data
    self.searchMode = NO;
    self.reloadData = NO;
    self.filteredCategories = [[NSMutableArray alloc] init];
    
    // Create database connections
    self.databaseConnection = [[DatabaseManager sharedInstance] newConnection];
    self.searchConnection = [[DatabaseManager sharedInstance] newConnection];
    self.muteConnection = [[DatabaseManager sharedInstance] newConnection];
    self.databaseConnection.name = NSStringFromClass([self class]);
    self.searchConnection.name = [NSStringFromClass([self class]) stringByAppendingString:@"_search"];
    self.muteConnection.name = [NSStringFromClass([self class]) stringByAppendingString:@"_mute"];
    
    // Freeze our connection for use on the main-thread.
    // This gives us a stable data-source that won't change until we tell it to.
    [self.databaseConnection beginLongLivedReadTransaction];
    
    // Try to setup mappings
    [self setupMainMapping];
    [self setupSearchMapping];
    [self setupUnreadMapping];
    
    // Create search queue to use in mapping
    self.searchQueue = [[YapDatabaseSearchQueue alloc] init];
    
    // Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:[DatabaseManager sharedInstance].database];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateCell:)
                                                 name:UPDATE_CELL_NOTIFICATION_NAME
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateCell:)
                                                 name:UPDATE_CHATS_NOTIFICATION_NAME
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"EDQueueJobDidSucceed"
                                               object:nil];
    
    // Remove extra lines
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:v];

    if ([SettingsKeys getBusinessId] && [[SettingsKeys getBusinessId] length] > 0) {
        // Register for push notifications and send tags
        [[CustomAblyRealtime sharedInstance] initAbly];
        [[CustomAblyRealtime sharedInstance] subscribeToChannels];
        [[CustomAblyRealtime sharedInstance] subscribeToPushNotifications];
        [NotificationPermissions canSendNotifications];
    } else {
        [AppJobs addBusinessDataJob];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barTintColor = [Colors purpleNavbar];
    [self updateBadge];

    if (self.reloadData) {
        [self.tableView reloadData];
        self.reloadData = NO;
    }

    [self.tableView setContentOffset:CGPointMake(0, self.searchController.searchBar.frame.size.height) animated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.cellUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                                            target:self
                                                          selector:@selector(updateVisibleCells:)
                                                          userInfo:nil
                                                           repeats:YES];

    [PFCloud callFunctionInBackground:@"getLatestManagerConversations"
                       withParameters:@{@"businessId": [SettingsKeys getBusinessId]}
                                block:^(id  _Nullable object, NSError * _Nullable error)
     {
         if (!error) {
             NSArray *contacts = [NSJSONSerialization JSONObjectWithData:[object dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:0
                                                                   error:&error];

             if (!error) {
                 [contacts enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                     NSDictionary *customer = (NSDictionary*)obj;
                     [YapContact saveContactWithDictionary:customer block:nil];
                 }];
             }
         }
     }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.lastTableViewPosition = self.tableView.contentOffset;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.cellUpdateTimer invalidate];
    self.cellUpdateTimer = nil;
}

- (void)receivedNotification:(NSNotification *)notification
{
    NSDictionary *job = [notification valueForKey:@"object"];

    if ([[job objectForKey:@"task"] isEqualToString:@"businessDataJob"]) {
        // Register for push notifications and send tags
        [[CustomAblyRealtime sharedInstance] initAbly];
        [[CustomAblyRealtime sharedInstance] subscribeToChannels];
        [[CustomAblyRealtime sharedInstance] subscribeToPushNotifications];
        [AppJobs addDownloadAvatarJob:[SettingsKeys getAvatarUrl]];
        [((AppDelegate *)[[UIApplication sharedApplication] delegate]).timer fire];
    }
}

-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (CGPointEqualToPoint(self.lastTableViewPosition, CGPointMake(0, 0))) {
        [self.tableView setContentOffset:CGPointMake(0, self.searchController.searchBar.frame.size.height) animated:NO];
    } else {
        [self.tableView setContentOffset:self.lastTableViewPosition animated:NO];
    }
}

#pragma mark - UITableViewDelegate Methods -

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 75.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self createMoreActions:indexPath];
}

#pragma mark - UITableViewDataSource Methods -

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *simpleTableIdentifier = @"CustomChatCell";
    CustomChatCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[CustomChatCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    [cell configureCellWith:[self contactForIndexPath:indexPath] position:indexPath.row];

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.searchMode && self.searchMappings) {
        return [self.searchMappings numberOfSections];
    } else if (self.mappings) {
        return [self.mappings numberOfSections];
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchMappings && self.searchMode) {
        return [self.searchMappings numberOfItemsInSection:section];
    } else {
        if (self.mappings && [self.mappings numberOfItemsInSection:section] > 0) {
            self.emptyView.hidden = YES;
            return [self.mappings numberOfItemsInSection:section];
        } else {
            self.emptyView.hidden = NO;
            return 0;
        }
    }
}

#pragma mark - Find Method -

- (YapContact *)contactForIndexPath:(NSIndexPath *)indexPath {
    __block YapContact *buddy = nil;
    // At this point is sure variable mappings is always distinct to nil
    
    if (self.searchMappings && self.searchMode) {
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            buddy = [[transaction extension:SearchChatFTSExtensionName] objectAtIndexPath:indexPath withMappings:self.searchMappings];
        }];
    } else {
        [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            buddy = [[transaction extension:ConversaDatabaseViewExtensionName] objectAtIndexPath:indexPath withMappings:self.mappings];
        }];
    }
    
    return buddy;
}

#pragma mark - UISearchBarDelegate Methods -

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self performSearch:searchBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self performSearch:searchBar];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    if (!self.searchMode) {
        self.searchMode = YES;
        [self.tableView reloadData];
    }
    [searchBar setShowsCancelButton:YES animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchMode = NO;
    [self.tableView reloadData];
    [searchBar setShowsCancelButton:NO animated:YES];
}

#pragma mark - YapDatabase Methods -

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Jump to the most recent commit.
    // End & Re-Begin the long-lived transaction atomically.
    // Also grab all the notifications for all the commits that I jump.
    // If the UI is a bit backed up, I may jump multiple commits.
    NSArray *notifications = [self.databaseConnection beginLongLivedReadTransaction];

    if (self.mappings == nil || self.searchMappings == nil || self.unreadConversationsMappings == nil) {
        [self setupMainMapping];
        [self setupSearchMapping];
        [self setupUnreadMapping];
        return;
    }
    
    if ([notifications count] <= 0) {
        // Since we moved our databaseConnection to a new commit,
        // we need to update the mappings too.
        [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [self.mappings updateWithTransaction:transaction];
            [self.searchMappings updateWithTransaction:transaction];
            [self.unreadConversationsMappings updateWithTransaction:transaction];
        }];
        return; // Already processed commit
    }

    NSArray *rowChanges = nil;
    NSArray *searchRowChanges = nil;
    NSArray *unreadSectionChanges = nil;
    NSArray *unreadRowChanges = nil;
    
    [[self.databaseConnection ext:ConversaDatabaseViewExtensionName] getSectionChanges:NULL
                                                                            rowChanges:&rowChanges
                                                                      forNotifications:notifications
                                                                          withMappings:self.mappings];
    
    [[self.databaseConnection ext:SearchChatFTSExtensionName] getSectionChanges:NULL
                                                                     rowChanges:&searchRowChanges
                                                               forNotifications:notifications
                                                                   withMappings:self.searchMappings];
    
    [[self.databaseConnection ext:UnreadConversationsViewExtensionName] getSectionChanges:&unreadSectionChanges
                                                                               rowChanges:&unreadRowChanges
                                                                         forNotifications:notifications
                                                                             withMappings:self.unreadConversationsMappings];
    
    if ([unreadSectionChanges count] || [unreadRowChanges count]) {
        [self updateBadge];
    }
    
    if ([rowChanges count]) {
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
                    //[self.tableView reloadRowsAtIndexPaths:@[rowChange.indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [((CustomChatCell*)[self.tableView cellForRowAtIndexPath:rowChange.indexPath]) updateLastMessage:NO];
                    break;
                }
            }
        }
        
        [self.tableView endUpdates];
    } else if ([searchRowChanges count] && self.searchMode) {
        [self.tableView beginUpdates];
        
        for (YapDatabaseViewRowChange *rowChange in searchRowChanges)
        {
            switch (rowChange.type)
            {
                case YapDatabaseViewChangeDelete :
                {
                    [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                case YapDatabaseViewChangeInsert :
                {
                    [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                case YapDatabaseViewChangeMove :
                {
                    [self.tableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                    break;
                }
                case YapDatabaseViewChangeUpdate :
                {
                    [self.tableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                     withRowAnimation:UITableViewRowAnimationNone];
                    break;
                }
            }
        }
        
        [self.tableView endUpdates];
    }
}

#pragma mark - Navigation Method -

- (IBAction)startBrowsingPressed:(UIStateButton *)sender {
    UIViewController *view = ((UINavigationController*)[self.tabBarController.viewControllers objectAtIndex:2]).visibleViewController;
    
    if ([view isKindOfClass:[SettingsViewController class]]) {
        [view performSegueWithIdentifier:@"conversaLinkSegue" sender:nil];
    }

    [self.tabBarController setSelectedIndex:2];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"FromChatsToChat"]) {
        YapContact *bs = ((CustomChatCell*)sender).business;
        // Get reference to the destination view controller
        ConversationViewController *destinationViewController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
        destinationViewController.position = ((CustomChatCell*)sender).position;
        [destinationViewController initWithBuddy:bs];
    }
}

#pragma mark - Action Methods -

- (void)updateBadge {
    if (self.unreadConversationsMappings == nil) {
        return;
    }
    
    NSUInteger numberUnreadConversations = [self.unreadConversationsMappings numberOfItemsInAllGroups];
    
    if (numberUnreadConversations > 99) {
        [[self navigationController] tabBarItem].badgeValue = @"99+";
    } else if (numberUnreadConversations > 0) {
        [[self navigationController] tabBarItem].badgeValue = [NSString stringWithFormat:@"%d", (int)numberUnreadConversations];
    } else {
        [[self navigationController] tabBarItem].badgeValue = nil;
    }
}

- (void)updateCell:(NSNotification *)notification {
    if ([[notification name] isEqualToString:UPDATE_CELL_NOTIFICATION_NAME]) {
        NSString *objectId = [notification.userInfo objectForKey:UPDATE_CELL_DIC_KEY];
        NSArray *indexPathsArray = [self.tableView indexPathsForVisibleRows];
        
        for(NSIndexPath *indexPath in indexPathsArray) {
            CustomChatCell * cell = (CustomChatCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            if ([cell.business.uniqueId isEqualToString:objectId]) {
                [cell updateLastMessage:NO];
                break;
            }
        }
    } else if ([[notification name] isEqualToString:UPDATE_CHATS_NOTIFICATION_NAME]) {
        // Reload data with boolean flag
        self.reloadData = YES;
    }
}

- (void)updateVisibleCells:(id)sender {
    NSArray * indexPathsArray = [self.tableView indexPathsForVisibleRows];
    
    for(NSIndexPath *indexPath in indexPathsArray) {
        UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [(CustomChatCell *)cell updateLastMessage:YES];
    }
}

- (void)performSearch:(UISearchBar *)searchBar {
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    NSArray *searchComponents = [searchBar.text componentsSeparatedByCharactersInSet:whitespace];
    NSMutableString *query = [NSMutableString string];
    
    for (NSString *term in searchComponents) {
        [query appendFormat:@"%@", term];
    }
    
    [query appendString:@"*"];
    
    [self.searchQueue enqueueQuery:query];
    [self.searchConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [[transaction ext:SearchChatFTSExtensionName] performSearchWithQueue:self.searchQueue];
    }];
}

- (NSArray *)createMoreActions:(NSIndexPath *)indexPath {
    UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal
                                                                          title:NSLocalizedString(@"chats_cell_action_title", nil)
                                                                        handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
    {
        UIAlertController * view =  [UIAlertController
                                     alertControllerWithTitle:nil
                                     message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];

        YapContact *contact = [self contactForIndexPath:indexPath];

        UIAlertAction* clean = [UIAlertAction actionWithTitle:NSLocalizedString(@"chats_alert_action_clear_conversation", nil)
                                                        style:UIAlertActionStyleDestructive
                                                      handler:^(UIAlertAction * action)
                                {
                                    [self.muteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
                                     {
                                         [YapMessage deleteAllMessagesForBuddyId:contact.uniqueId transaction:transaction];
                                     } completionBlock:^{
                                         [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_CELL_NOTIFICATION_NAME
                                                                                             object:nil
                                                                                           userInfo:@{UPDATE_CELL_DIC_KEY: contact.uniqueId}];
                                     }];

                                    [view dismissViewControllerAnimated:YES completion:nil];
                                    [self.tableView setEditing:NO animated:YES];
                                }];

        UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"common_action_cancel", nil)
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action)
                                 {
                                     [view dismissViewControllerAnimated:YES completion:nil];
                                     [self.tableView setEditing:NO animated:YES];
                                 }];

        [view addAction:clean];
        [view addAction:cancel];
        [self presentViewController:view animated:YES completion:nil];
    }];

    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive
                                                                            title:NSLocalizedString(@"chats_cell_action_delete", nil)
                                                                          handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
    {
        YapContact *cellBuddy = [self contactForIndexPath:indexPath];

        [[DatabaseManager sharedInstance].newConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [cellBuddy removeWithTransaction:transaction];
        }];
    }];

    return @[deleteAction, editAction];
}

#pragma mark - Setup Mappings Methods -

- (void)setupMainMapping {
    if (self.mappings) {
        return;
    }

    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        if ([transaction ext:ConversaDatabaseViewExtensionName]) {
            self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[ConversationGroup]
                                                                       view:ConversaDatabaseViewExtensionName];
            [self.mappings updateWithTransaction:transaction];
            
            if (self.searchMappings) {
                [self.searchMappings updateWithTransaction:transaction];
            }
            if (self.unreadConversationsMappings) {
                [self.unreadConversationsMappings updateWithTransaction:transaction];
            }
            
            [self.tableView reloadData];
        } else {
            // View isn't ready yet.
            // Wait for YapDatabaseModifiedNotification.
        }
    }];
}

- (void)setupSearchMapping {
    if (self.searchMappings) {
        return;
    }
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        if ([transaction ext:SearchChatFTSExtensionName]) {
            self.searchMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[ConversationGroup]
                                                                             view:SearchChatFTSExtensionName];
            [self.searchMappings updateWithTransaction:transaction];
            
            if (self.mappings) {
                [self.mappings updateWithTransaction:transaction];
            }
            if (self.unreadConversationsMappings) {
                [self.unreadConversationsMappings updateWithTransaction:transaction];
            }
        }
    }];
}

- (void)setupUnreadMapping {
    if (self.unreadConversationsMappings) {
        return;
    }
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        if ([transaction ext:UnreadConversationsViewExtensionName]) {
            self.unreadConversationsMappings = [[YapDatabaseViewMappings alloc] initWithGroupFilterBlock:^(NSString *group, YapDatabaseReadTransaction *transaction) {
                return YES; // Include all unread conversations
            } sortBlock:^NSComparisonResult(NSString *group1, NSString *group2, YapDatabaseReadTransaction *transaction) {
                return NSOrderedSame;
            } view:UnreadConversationsViewExtensionName];
            
            [self.unreadConversationsMappings updateWithTransaction:transaction];
            
            if (self.mappings) {
                [self.mappings updateWithTransaction:transaction];
            }
            if (self.searchMappings) {
                [self.searchMappings updateWithTransaction:transaction];
            }
            
            [self updateBadge];
        }
    }];
}

@end
