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
#import "Business.h"
#import "Constants.h"
#import "YapMessage.h"
#import "YapContact.h"
#import "AppDelegate.h"
#import "DatabaseView.h"
#import "SettingsKeys.h"
#import "CustomChatCell.h"
#import "DatabaseManager.h"
#import "OneSignalService.h"
#import "NotificationPermissions.h"
#import "ConversationViewController.h"
#import <Parse/Parse.h>
#import <YapDatabase/YapDatabaseView.h>
#import <YapDatabase/YapDatabaseSearchQueue.h>

@interface ChatsViewController ()

@property (weak, nonatomic) IBOutlet UIView *emptyView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *noMessagesLine1;
@property (weak, nonatomic) IBOutlet UILabel *noMessagesLine2;
@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSMutableArray *filteredCategories;
@property (nonatomic, strong) NSTimer *cellUpdateTimer;
@property (nonatomic, assign) BOOL searchMode;
@property (nonatomic, assign) BOOL reloadData;

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseConnection *searchConnection;
@property (nonatomic, strong) YapDatabaseConnection *muteConnection;
@property (nonatomic, strong) YapDatabaseSearchQueue *searchQueue;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic, strong) YapDatabaseViewMappings *searchMappings;
@property (nonatomic, strong) YapDatabaseViewMappings *unreadConversationsMappings;

@property(nonatomic) BOOL visible;

@end

@implementation ChatsViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    // If we are using this same view controller to present the results
    // dimming it out wouldn't make sense.  Should set probably only set
    // this to yes if using another controller to display the search results.
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.showsScopeBar = NO;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.placeholder = NSLocalizedString(@"Search in chats", nil);
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
    self.noMessagesLine2.adjustsFontSizeToFitWidth = YES;
    self.noMessagesLine2.minimumScaleFactor = 1;
    
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
    
    // Add observers
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
    
    // Register for push notifications and send tags
    //[[CustomAblyRealtime sharedInstance] initAbly];
    [[OneSignalService sharedInstance] registerForPushNotifications];
    [[OneSignalService sharedInstance] startTags];
    
    // Remove extra lines
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:v];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YapDatabaseModifiedNotification object:[DatabaseManager sharedInstance].database];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UPDATE_CELL_NOTIFICATION_NAME object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UPDATE_CHATS_NOTIFICATION_NAME object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [CustomAblyRealtime sharedInstance].delegate = self;
    [self updateBadge];
    self.navigationController.navigationBar.barTintColor = [Colors greenColor];
    
    if (self.reloadData) {
        [self.tableView reloadData];
        self.reloadData = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.visible = true;
    self.cellUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60.0
                                                            target:self
                                                          selector:@selector(updateVisibleCells:)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.visible = false;
    [self.cellUpdateTimer invalidate];
    self.cellUpdateTimer = nil;
}

#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
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
    
    [cell configureCellWith:[self contactForIndexPath:indexPath]];
    
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
        if (self.mappings && [self.mappings numberOfItemsInSection:section]) {
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

#pragma mark - ConversationListener Methods -

- (void) messageReceived:(NSDictionary *)message {
    //    [PubNubController processMessage:message userState:NO setView:NO];
    //    NSArray * indexPathsArray = [self.tableView indexPathsForVisibleRows];
    //
    //    for(NSIndexPath *indexPath in indexPathsArray) {
    //        CustomChatCell * cell = (CustomChatCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    //        if ([cell.business.uniqueId isEqualToString:message.from]) {
    //            [cell updateLastMessage:NO];
    //            break;
    //        }
    //    }
}

- (void) fromUser:(NSString*)objectId userIsTyping:(BOOL)isTyping {
    NSArray * indexPathsArray = [self.tableView indexPathsForVisibleRows];
    
    for(NSIndexPath *indexPath in indexPathsArray) {
        CustomChatCell * cell = (CustomChatCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        if ([cell.business.uniqueId isEqualToString:objectId]) {
            [cell setIsTypingText:isTyping];
            break;
        }
    }
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
    
    // If the view isn't visible, we might decide to skip the UI animation stuff.
    if (!self.visible) {
        // Since we moved our databaseConnection to a new commit,
        // we need to update the mappings too.
        [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [self.mappings updateWithTransaction:transaction];
            [self.searchMappings updateWithTransaction:transaction];
            [self.unreadConversationsMappings updateWithTransaction:transaction];
        }];
        return;
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"FromChatsToChat"]) {
        YapContact *bs = ((CustomChatCell*)sender).business;
        // Get reference to the destination view controller
        ConversationViewController *destinationViewController = [segue destinationViewController];
        // Pass any objects to the view controller here, like...
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
        NSArray * indexPathsArray = [self.tableView indexPathsForVisibleRows];
        
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
        if ([cell isKindOfClass:[CustomChatCell class]]) {
            [(CustomChatCell *)cell updateLastMessage:YES];
        }
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
    UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Más" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                        {
                                            UIAlertController * view =  [UIAlertController
                                                                         alertControllerWithTitle:nil
                                                                         message:nil
                                                                         preferredStyle:UIAlertControllerStyleActionSheet];
                                            
                                            YapContact *contact = [self contactForIndexPath:indexPath];
                                            
                                            if (contact.mute) {
                                                
                                                UIAlertAction* unmute  = [UIAlertAction actionWithTitle:@"No silenciar"
                                                                                                  style:UIAlertActionStyleDefault
                                                                                                handler:^(UIAlertAction * action)
                                                                          {
                                                                              [contact programActionInHours:0 isMuting:NO];
                                                                              // Update contact
                                                                              contact.mute = NO;
                                                                              [self.muteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
                                                                               {
                                                                                   [contact saveWithTransaction:transaction];
                                                                               }];
                                                                              
                                                                              [view dismissViewControllerAnimated:YES completion:nil];
                                                                          }];
                                                [view addAction:unmute];
                                            } else {
                                                UIAlertAction* mute  = [UIAlertAction actionWithTitle:@"Silenciar"
                                                                                                style:UIAlertActionStyleDefault
                                                                                              handler:^(UIAlertAction * action)
                                                                        {
                                                                            // Mostrar opciones siguientes
                                                                            [view dismissViewControllerAnimated:YES completion:nil];
                                                                            [self selectMuteTimeToContact:[contact copy]];
                                                                        }];
                                                
                                                [view addAction:mute];
                                            }
                                            
                                            if (contact.blocked) {
                                                UIAlertAction* unblock = [UIAlertAction actionWithTitle:@"Desbloquear"
                                                                                                  style:UIAlertActionStyleDefault
                                                                                                handler:^(UIAlertAction * action)
                                                                          {
                                                                              contact.blocked = NO;
                                                                              [self.muteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
                                                                               {
                                                                                   [contact saveWithTransaction:transaction];
                                                                               }];
                                                                              
                                                                              //                                          [[PubNubService sharedInstance] subscribeToChannels:@[[contact getPrivateChannel]]];
                                                                              
                                                                              [[NSNotificationCenter defaultCenter] postNotificationName:BLOCK_NOTIFICATION_NAME
                                                                                                                                  object:nil
                                                                                                                                userInfo:nil];
                                                                              
                                                                              [view dismissViewControllerAnimated:YES completion:nil];
                                                                          }];
                                                
                                                [view addAction:unblock];
                                            } else {
                                                UIAlertAction* block = [UIAlertAction actionWithTitle:@"Bloquear"
                                                                                                style:UIAlertActionStyleDefault
                                                                                              handler:^(UIAlertAction * action)
                                                                        {
                                                                            contact.blocked = YES;
                                                                            [self.muteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
                                                                             {
                                                                                 [contact saveWithTransaction:transaction];
                                                                             }];
                                                                            
                                                                            //                                        [[PubNubService sharedInstance] unsubscribeToChannels:@[[contact getPrivateChannel]]];
                                                                            
                                                                            [[NSNotificationCenter defaultCenter] postNotificationName:BLOCK_NOTIFICATION_NAME
                                                                                                                                object:nil
                                                                                                                              userInfo:nil];
                                                                            
                                                                            [view dismissViewControllerAnimated:YES completion:nil];
                                                                        }];
                                                
                                                [view addAction:block];
                                            }
                                            
                                            UIAlertAction* clean = [UIAlertAction actionWithTitle:@"Limpiar conversación"
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
                                                                    }];
                                            
                                            UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancelar"
                                                                                             style:UIAlertActionStyleCancel
                                                                                           handler:^(UIAlertAction * action)
                                                                     {
                                                                         [view dismissViewControllerAnimated:YES completion:nil];
                                                                     }];
                                            
                                            
                                            [view addAction:clean];
                                            [view addAction:cancel];
                                            [self presentViewController:view animated:YES completion:nil];
                                        }];
    
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Eliminar" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath)
                                          {
                                              YapContact *cellBuddy = [self contactForIndexPath:indexPath];
                                              
                                              [[DatabaseManager sharedInstance].newConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                                                  [cellBuddy removeWithTransaction:transaction];
                                              }];
                                          }];
    
    return @[deleteAction, editAction];
}

- (void)selectMuteTimeToContact:(YapContact *)contact {
    UIAlertController * view =  [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* one = [UIAlertAction actionWithTitle:@"12 horas"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action)
                          {
                              [contact programActionInHours:12 isMuting:YES];
                              // Update contact
                              contact.mute = YES;
                              [self.muteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                                  [contact saveWithTransaction:transaction];
                              }];
                              [view dismissViewControllerAnimated:YES completion:nil];
                          }];
    
    UIAlertAction* two = [UIAlertAction actionWithTitle:@"1 día"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action)
                          {
                              [contact programActionInHours:24 isMuting:YES];
                              // Update contact
                              contact.mute = YES;
                              [self.muteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                                  [contact saveWithTransaction:transaction];
                              }];
                              [view dismissViewControllerAnimated:YES completion:nil];
                          }];
    
    UIAlertAction* three = [UIAlertAction actionWithTitle:@"3 días"
                                                    style:UIAlertActionStyleDefault
                                                  handler:^(UIAlertAction * action)
                            {
                                [contact programActionInHours:72 isMuting:YES];
                                // Update contact
                                contact.mute = YES;
                                [self.muteConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                                    [contact saveWithTransaction:transaction];
                                }];
                                [view dismissViewControllerAnimated:YES completion:nil];
                            }];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancelar"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action)
                             {
                                 [view dismissViewControllerAnimated:YES completion:nil];
                             }];
    
    
    [view addAction:one];
    [view addAction:two];
    [view addAction:three];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
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
        } else {
            // View isn't ready yet.
            // Wait for YapDatabaseModifiedNotification.
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
        } else {
            // View isn't ready yet.
            // Wait for YapDatabaseModifiedNotification.
        }
    }];
}

@end
