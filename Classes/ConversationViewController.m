
//  ConversationViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 11/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//
//  BASED ON
//
//  MessagesViewController.m
//  Signal
//
//  Created by Dylan Bourgeois on 28/10/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.
//
//
//  OTRMessagesViewController.m
//  Off the Record
//
//  Created by David Chiles on 5/12/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "ConversationViewController.h"

@import AVKit;
@import YapDatabase;
@import AVFoundation;
#import "Log.h"
#import "Image.h"
#import "Flurry.h"
#import "Camera.h"
#import "Colors.h"
#import "AppJobs.h"
#import "MapView.h"
#import "Incoming.h"
#import "Constants.h"
#import "Utilities.h"
#import "YapContact.h"
#import "YapMessage.h"
#import "SettingsKeys.h"
#import "DatabaseView.h"
#import "UIStateButton.h"
#import "ParseValidation.h"
#import "DatabaseManager.h"
#import "NSNumber+Conversa.h"
#import "ChatsViewController.h"
#import "NSFileManager+Conversa.h"
#import "NotificationPermissions.h"

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <YapDatabase/YapDatabaseView.h>
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "ConversaManager-Swift.h"

#include <stdlib.h>

#define kYapDatabaseRangeLength    25
#define kYapDatabaseRangeMaxLength 300
#define kYapDatabaseRangeMinLength 20
#define kInputToolbarMaximumHeight 150
#define kWaitingTimeInSeconds 3.5

@interface ConversationViewController ()

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseConnection *editingDatabaseConnection;
@property (nonatomic, strong) YapDatabaseConnection *messageDatabaseConnection;

@property (nonatomic, strong) YapDatabaseViewMappings *messageMappings;

@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImage;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImage;

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) UIImageView *avatarView;
@property (nonatomic, strong) UILabel *titleView;
@property (nonatomic, strong) UILabel *subTitle;

@property (nonatomic) NSUInteger page;

@property(nonatomic) BOOL visible;
@property(nonatomic) BOOL typingFlag;

@property(nonatomic, strong) NSTimer *timeWaiting;

@end

@implementation ConversationViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];

    self.typingFlag = NO;
    self.messages = [[NSMutableArray alloc] init];
    
    // Bar tint
    self.navigationController.navigationBar.barTintColor = [Colors whiteNavbar];

    //Set up message accessory button delegate and configuration
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    self.automaticallyScrollsToMostRecentMessage = YES;
    
    // Setup UI methods
    [self initializeBubbles];
    [self initializeInputToolbar];
    [self initializeCellMenus];
    
    // Create database connections
    self.databaseConnection = [[DatabaseManager sharedInstance] newConnection];
    self.editingDatabaseConnection = [[DatabaseManager sharedInstance] newConnection];
    self.messageDatabaseConnection = [[DatabaseManager sharedInstance] newConnection];

    self.databaseConnection.name = NSStringFromClass([self class]);
    self.editingDatabaseConnection.name = [NSStringFromClass([self class]) stringByAppendingString:@"_edit"];
    self.messageDatabaseConnection.name = [NSStringFromClass([self class]) stringByAppendingString:@"_msg"];
    
    // Freeze our connection for use on the main-thread.
    // This gives us a stable data-source that won't change until we tell it to.
    [self.databaseConnection beginLongLivedReadTransaction];
    
    // Try to setup mapping
    [self setupMessageMapping];
    
    // Set visible for UI changes
    self.visible = true;

    // Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:[DatabaseManager sharedInstance].database];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedTextViewChangedNotification:)
                                                 name:UITextViewTextDidChangeNotification
                                               object:self.inputToolbar.contentView.textView];

    // Load
    [self loadNavigationBarInformation];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:YapDatabaseModifiedNotification object:[DatabaseManager sharedInstance].database];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:self.inputToolbar.contentView.textView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.barTintColor = [Colors whiteNavbar];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.visible = true;
    [CustomAblyRealtime sharedInstance].delegate = self;
    
    if (self.buddy) {
        if ([self.buddy.composingMessageString length] > 0) {
            [self.inputToolbar.contentView.textView setText:self.buddy.composingMessageString];
            CGFloat fixedWidth = self.inputToolbar.contentView.textView.frame.size.width;
            CGSize newSize = [self.inputToolbar.contentView.textView sizeThatFits:CGSizeMake(fixedWidth, 140.0f)];
            CGRect newFrame = self.inputToolbar.contentView.textView.frame;
            newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
            self.inputToolbar.contentView.textView.frame = newFrame;
            self.inputToolbar.contentView.rightBarButtonItem.enabled = YES;
        }
    }
    
    __block BOOL result = NO;
    [self.messageDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        result = [self.buddy setAllMessagesView:transaction];
    } completionBlock:^{
        [self.editingDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            if (self.checkIfAlreadyAdded) {
                [self.buddy saveWithTransaction:transaction];
            }
        } completionBlock:^{
            if (result) {
                [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_CELL_NOTIFICATION_NAME
                                                                    object:nil
                                                                  userInfo:@{UPDATE_CELL_DIC_KEY: self.buddy.uniqueId}];
            }
        }];
    }];
    
    self.collectionView.collectionViewLayout.springinessEnabled = NO;

    NSString *business_id = [SettingsKeys getBusinessId];
    [Flurry logEvent:@"manager_chat_duration" withParameters:@{@"business": (business_id) ? business_id : @""} timed:YES];

    [PFCloud callFunctionInBackground:@"getLatestMessagesByConversation"
                       withParameters:@{@"customerId": self.buddy.uniqueId,
                                        @"businessId": [SettingsKeys getBusinessId],
                                        @"fromCustomer": @NO}
                                block:^(id  _Nullable object, NSError * _Nullable error)
     {
         if (!error) {
             NSArray *messages = [NSJSONSerialization JSONObjectWithData:[object dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:0
                                                                   error:&error];

             if (!error) {
                 [messages enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                     NSDictionary *message = (NSDictionary*)obj;
                     [YapMessage saveMessageWithDictionary:message block:nil];
                 }];
             }
         }
     }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveCurrentMessageText];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.visible = false;
    [Flurry endTimedEvent:@"manager_chat_duration" withParameters:nil];
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    [super willMoveToParentViewController:parent];
    if (parent == nil) {
        UIViewController *last = [self.navigationController.viewControllers firstObject];
        if (last) {
            if ([last isKindOfClass:[ChatsViewController class]]) {
                self.navigationController.navigationBar.barTintColor = [Colors purpleNavbar];
                self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
            }
        }
    }
}

#pragma mark - Setup Methods -

- (void)loadNavigationBarInformation {
    UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,38,38)];
    logo.image = [self getConversationAvatar:self.position];

    // Width constraint
    [logo addConstraint:[NSLayoutConstraint constraintWithItem:logo
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute: NSLayoutAttributeNotAnAttribute
                                                    multiplier:1
                                                      constant:38]];

    // Height constraint
    [logo addConstraint:[NSLayoutConstraint constraintWithItem:logo
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute: NSLayoutAttributeNotAnAttribute
                                                    multiplier:1
                                                      constant:38]];

    logo.layer.cornerRadius = 19;
    logo.layer.masksToBounds = YES;
    self.avatarView = logo;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:logo];

    UIView *view = [[NSBundle mainBundle] loadNibNamed:@"ChatNavBarView" owner:self options:nil][0];
    self.titleView = (UILabel *)[view viewWithTag:120];
    [self.titleView setText:self.buddy.displayName];
    self.subTitle = (UILabel *)[view viewWithTag:121];
    [self.subTitle setText:@""];
    self.subTitle.hidden = YES;

    UITapGestureRecognizer *profileTap = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(goToProfile:)];
    profileTap.numberOfTapsRequired = 1;
    [view setUserInteractionEnabled:YES];
    [view addGestureRecognizer:profileTap];

    self.navigationItem.titleView = view;
}

- (void)refreshNavigationBarInformation:(YapContact *)buddy {
    self.avatarView.image = [self getConversationAvatar:self.position];
    [self.titleView setText:buddy.displayName];
    self.subTitle.hidden = YES;
}

- (UIImage*)getConversationAvatar:(NSInteger)position {
    if (position == -1) {
        position = arc4random_uniform(14) + 1;
    } else {
        position++;
    }

    if (position % 7 == 0) {
        return [UIImage imageNamed:@"ic_user_one"];
    } else if (position % 6 == 0) {
        return [UIImage imageNamed:@"ic_user_two"];
    } else if (position % 5 == 0) {
        return [UIImage imageNamed:@"ic_user_three"];
    } else if (position % 4 == 0) {
        return [UIImage imageNamed:@"ic_user_four"];
    } else if (position % 3 == 0) {
        return [UIImage imageNamed:@"ic_user_five"];
    } else if (position % 2 == 0) {
        return [UIImage imageNamed:@"ic_user_six"];
    } else {
        return [UIImage imageNamed:@"ic_user_seven"];
    }
}

- (void)setupMessageMapping {
    if (self.messageMappings) {
        return;
    }
    
    __block BOOL set = NO;
    
    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        if ([transaction ext:ChatDatabaseViewExtensionName]) {
            self.messageMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[self.buddy.uniqueId]
                                                                              view:ChatDatabaseViewExtensionName];
            [self.messageMappings updateWithTransaction:transaction];
            set = YES;
        } else {
            // View isn't ready yet.
            // Wait for YapDatabaseModifiedNotification.
        }
    }];
    
    if (set) {
        self.page = 0;
        [self updateRangeOptionsForPage:self.page];
        [self loadData];
        [self initializeCollectionViewLayout];
    }
}

- (void)initWithText:(YapContact *)buddy {
    if (self.buddy && buddy) {
        if (![self.buddy.uniqueId isEqualToString:buddy.uniqueId]) {
            [self saveCurrentMessageText];
            
            [self.inputToolbar.contentView.textView setText:buddy.composingMessageString];
            
            // Clear current messages & update mappings
            [self.messages removeAllObjects];
            self.messageMappings = [[YapDatabaseViewMappings alloc] initWithGroups:@[buddy.uniqueId] view:ChatDatabaseViewExtensionName];
            
            self.page = 0;
            self.position = -1;
            [self updateRangeOptionsForPage:self.page];
            
            [self.editingDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
                [self.messageMappings updateWithTransaction:transaction];
                [self loadData];
            }];
            
            [self refreshNavigationBarInformation:buddy];
        }
    }
    
    // Update reference
    self.buddy = buddy;
    self.typingFlag = NO;
}

- (void)initWithBuddy:(YapContact *)buddy {
    self.checkIfAlreadyAdded = YES;
    [self initWithText:buddy];
}

- (void)initWithBusiness:(Customer *)business withAvatarUrl:(NSString*)url {
    NSDictionary *values = [YapContact saveContactWithParseBusiness:business
                                                      andConnection:[DatabaseManager sharedInstance].newConnection
                                                            andSave:NO];
    YapContact *newBuddy = (YapContact*)[values valueForKey:kNSDictionaryCustomer];

    self.checkIfAlreadyAdded = [[values valueForKey:kNSDictionaryChangeValue] boolValue];
    [self initWithText:newBuddy];
}

- (void)initializeBubbles {
    JSQMessagesBubbleImageFactory *bubbleImageFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    self.outgoingBubbleImage = [bubbleImageFactory outgoingMessagesBubbleImageWithColor:[Colors outgoing]];
    self.incomingBubbleImage = [bubbleImageFactory incomingMessagesBubbleImageWithColor:[Colors incoming]];
    // No avatars
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
}

- (void)initializeInputToolbar {
    self.inputToolbar.contentView.textView.placeHolder = NSLocalizedString(@"conversation_inputtoolbar_placeholder", nil);
    // Set a maximum height for the input toolbar
    self.inputToolbar.maximumHeight = kInputToolbarMaximumHeight;
    // The library will call the correct selector for each button, based on this value
    //self.inputToolbar.sendButtonOnRight = YES;
    // Attachment Button
    UIButton *customLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    customLeftButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    customLeftButton.frame = CGRectMake(0, 0, 30, 30);
    UIImage * buttonImage = [UIImage imageNamed:@"ic_attachment"];
    [customLeftButton setContentMode:UIViewContentModeScaleAspectFit];
    [customLeftButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    self.inputToolbar.contentView.leftBarButtonItem = customLeftButton;

    // Add sign up button properties
    UIStateButton *customRightButton = [UIStateButton buttonWithType:UIButtonTypeCustom];
    customRightButton.frame = CGRectMake(0, 0, 32, 32);
    customRightButton.layer.cornerRadius = customRightButton.frame.size.width / 2;
    customRightButton.clipsToBounds = YES;

    [customRightButton setBackgroundColor:[Colors purple] forState:UIControlStateNormal];
    [customRightButton setBackgroundColor:[Colors darkerPurple] forState:UIControlStateHighlighted];
    [customRightButton setBackgroundColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

    UIImage *sendImage = [UIImage imageNamed:@"ic_send"];
    UIImage *scaledImage = [UIImage imageWithCGImage:[sendImage CGImage]
                                               scale:(sendImage.scale * 1.2)
                                         orientation:(sendImage.imageOrientation)];
    [customRightButton setImage:scaledImage forState:UIControlStateNormal];
    [customRightButton setImage:scaledImage forState:UIControlStateDisabled];
    [customRightButton setImage:scaledImage forState:UIControlStateHighlighted];

    self.inputToolbar.contentView.rightBarButtonItem = customRightButton;
}

- (void)initializeCellMenus {
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(actionDelete:)];
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(actionCopy:)];
    UIMenuItem *menuItemCopy = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"conversation_menu_item_copy", nil) action:@selector(actionCopy:)];
    UIMenuItem *menuItemDelete = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"conversation_menu_item_delete", nil) action:@selector(actionDelete:)];
    [UIMenuController sharedMenuController].menuItems = @[menuItemCopy, menuItemDelete];
}

- (void)initializeCollectionViewLayout {
    if (self.collectionView) {
        self.collectionView.collectionViewLayout.sectionInset = UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0);
        self.collectionView.showsVerticalScrollIndicator = NO;
        self.collectionView.showsHorizontalScrollIndicator = NO;
        [self updateLoadEarlierVisible];
    }
}

- (YapMessage*)newYapMessageType:(NSInteger)type values:(NSDictionary*)values incoming:(BOOL)isIncoming {
    YapMessage *message = [[YapMessage alloc] init];
    message.view = YES;
    message.buddyUniqueId = self.buddy.uniqueId;
    message.incoming = isIncoming;
    message.messageType = type;

    switch (type) {
        case kMessageTypeText: {
            message.text = values[MESSAGE_TEXT_KEY];
            break;
        }
        case kMessageTypeLocation: {
            CLLocation *location = [[CLLocation alloc]
                                    initWithLatitude:[values[MESSAGE_LATI_KEY] doubleValue]
                                           longitude:[values[MESSAGE_LONG_KEY] doubleValue]];
            message.location = location;
            break;
        }
        case kMessageTypeImage:
        case kMessageTypeAudio:
        case kMessageTypeVideo: {
            message.filename = values[MESSAGE_FILENAME_KEY];
            message.bytes = [values[MESSAGE_SIZE_KEY] floatValue];
            break;
        }
    }

    return message;
}

- (void)saveCurrentMessageText {
    if (!self.buddy)
        return;
    
    /*
     * Only saves inputToolbar text if:
     *
     * 1. There is text in the textView, last composing string should have textView
     * text.
     *
     * 2. Last composing string has text and now textView doesn't have, last composing
     * string should now be empty
     */
    if(![self.buddy.composingMessageString isEqualToString:self.inputToolbar.contentView.textView.text])
    {
        if (!self.checkIfAlreadyAdded) {
            return;
        }

        self.buddy.composingMessageString = [self.inputToolbar.contentView.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self.editingDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            [self.buddy saveWithTransaction:transaction];
        }];
    }
}

- (void) loadData {
    NSUInteger collectionViewNumberOfItems = [self.messages count];
    NSUInteger numberMappingsItems = [self.messageMappings numberOfItemsInSection:0];
    
    if(numberMappingsItems > collectionViewNumberOfItems && numberMappingsItems > 0) {
        // Inserted new item, probably at the end
        // Get last message and test if isIncoming
        NSUInteger to = numberMappingsItems - collectionViewNumberOfItems;
        for (NSInteger i = 0; i < to; i++) {
            NSIndexPath *messageIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
            YapMessage *message = [self messageAtIndexPath:messageIndexPath];
            [self createMessage:message];
        }
    }
    
    [self.collectionView reloadData];
}

- (void) reloadData {
    NSUInteger collectionViewNumberOfItems = [self.messages count];
    NSUInteger numberMappingsItems         = [self.messageMappings numberOfItemsInSection:0];
    
    if(numberMappingsItems > collectionViewNumberOfItems && numberMappingsItems > 0) {
        // Inserted new item, probably at the end
        // Get last message and test if isIncoming
        NSUInteger from = numberMappingsItems - collectionViewNumberOfItems - 1;
        for (NSInteger i = from; i >= 0; i--) {
            NSIndexPath *messageIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
            YapMessage *message = [self messageAtIndexPath:messageIndexPath];
            [self preappendMessage:message];
        }
    }
    
    [self.collectionView reloadData];
}

- (void)createMessage:(YapMessage *)item {
    Incoming *incoming = [[Incoming alloc] init];
    JSQMessage *message = [incoming create:item];
    [self.messages addObject:message];
}

- (void)preappendMessage:(YapMessage *)item {
    Incoming *incoming = [[Incoming alloc] init];
    JSQMessage *message = [incoming create:item];
    [self.messages insertObject:message atIndex:0];
}

#pragma mark - Find Methods -

- (YapMessage *)messageAtIndexPath:(NSIndexPath *)indexPath {
    __block YapMessage *message = nil;

    [self.messageDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        YapDatabaseViewTransaction *viewTransaction = [transaction ext:ChatDatabaseViewExtensionName];
        NSUInteger row = indexPath.row;
        NSUInteger section = indexPath.section;

        NSAssert(row < [self.messageMappings numberOfItemsInSection:section], @"Cannot fetch message because row %d is >= numberOfItemsInSection %d", (int)row, (int)[self.messageMappings numberOfItemsInSection:section]);

        message = [viewTransaction objectAtRow:row inSection:section withMappings:self.messageMappings];
        NSParameterAssert(message != nil);
    }];

    return message;
}

#pragma mark - Decision Methods -

- (BOOL)canSendMessage {
    return (self.buddy.blocked) ? NO : YES;
}

#pragma mark - JSQMessagesViewController Methods -

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    if ([self canSendMessage]) {
        YapMessage *message = [self newYapMessageType:kMessageTypeText values:@{MESSAGE_TEXT_KEY: text} incoming:NO];
        [self sendWithYapMessage:message isLastMessage:YES withPFFile:nil];
    } else {
        [self showUnblockMessage];
    }
}

- (void)didPressAccessoryButton:(UIButton *)sender {
    if ([self canSendMessage]) {
        UIAlertController* view = [UIAlertController alertControllerWithTitle:nil
                                                                      message:nil
                                                               preferredStyle:UIAlertControllerStyleActionSheet];

        UIAlertAction* photoLibrary = [UIAlertAction actionWithTitle:NSLocalizedString(@"conversation_more_alert_action_library", nil)
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * action)
        {
            PresentPhotoLibrary(self, YES, IMAGE_LIMIT);
            [view dismissViewControllerAnimated:YES completion:nil];
        }];
        
        UIAlertAction* camera = [UIAlertAction actionWithTitle:NSLocalizedString(@"conversation_more_alert_action_camara", nil)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action)
        {
            PresentPhotoCamera(self, YES);
            [view dismissViewControllerAnimated:YES completion:nil];
        }];
        
        UIAlertAction* location = [UIAlertAction actionWithTitle:NSLocalizedString(@"conversation_more_alert_action_location", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action)
        {
            [self sendLocation];
            [view dismissViewControllerAnimated:YES completion:nil];
        }];
        
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"common_action_cancel", nil)
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action)
        {
            [view dismissViewControllerAnimated:YES completion:nil];
        }];

        [view addAction:photoLibrary];
        [view addAction:camera];
        [view addAction:location];
        [view addAction:cancel];
        [self presentViewController:view animated:YES completion:nil];
    } else {
        [self showUnblockMessage];
    }
}

#pragma mark - UICollectionViewDataSource Methods -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    JSQMessage *message = [self.messages objectAtIndex:indexPath.item];

    if (!message.isMediaMessage) {
        cell.textView.textColor = [Colors black];
        cell.textView.dataDetectorTypes = UIDataDetectorTypeAll;
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : [Colors black],
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }

    return cell;
}

#pragma mark - UICollectionViewDelegate Methods -

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return NO;
}

- (void)copy:(__unused id)sender {
    [[UIPasteboard generalPasteboard] setString:[self.inputToolbar.contentView.textView text]];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
    [super collectionView:collectionView shouldShowMenuForItemAtIndexPath:indexPath];
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    YapMessage *message = [self messageAtIndexPath:indexPath];
    
    if (message) {
        if (action == @selector(actionCopy:)) {
            if (message.messageType == kMessageTypeText)
                return YES;
        } else if (action == @selector(actionDelete:)) {
            return YES;
        }
    }
    
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(actionCopy:)) {
        [self actionCopy:indexPath];
        return;
    } else if(action == @selector(actionDelete:)) {
        [self actionDelete:indexPath];
        return;
    }
    
    [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
}

#pragma mark - JSQMessagesCollectionViewDataSource Methods -

- (NSString *)senderDisplayName {
    return @"user";
}

- (NSString *)senderId {
    return ([[SettingsKeys getBusinessId] length] == 0) ? @"" : [SettingsKeys getBusinessId];
}

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.messages objectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return ([self messageAtIndexPath:indexPath].isIncoming) ? self.incomingBubbleImage : self.outgoingBubbleImage;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self showDateAtIndexPath:indexPath]) {
        return [[JSQMessagesTimestampFormatter sharedFormatter]
                attributedTimestampForDate:[self messageAtIndexPath:indexPath].date];
    }

    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    YapMessage *msg = [self messageAtIndexPath:indexPath];

    if ([self shouldShowMessageStatusAtIndexPath:indexPath message:msg]) {
        NSMutableAttributedString *attributedString = nil;
        NSString *progressString = nil;
        BOOL error = NO;

        if (msg.getStatus == statusParseError) {
            error = YES;
            progressString = [NSString stringWithFormat:@"%@",
                              NSLocalizedString(@"conversation_message_info_failed", nil)];
        } else if (msg.getStatus == statusUploading) {
            if (msg.messageType == kMessageTypeText || msg.messageType == kMessageTypeLocation) {
                progressString = [NSString stringWithFormat:@"%@",
                                  NSLocalizedString(@"conversation_message_info_sending", nil)];
            } else {
                progressString = [NSString stringWithFormat:@"%@",
                                  NSLocalizedString(@"conversation_message_info_uploading", nil)];
            }
        } else if (msg.getStatus == statusDownloading) {
            progressString = [NSString stringWithFormat:@"%@",
                              NSLocalizedString(@"conversation_message_info_downloading", nil)];
        } else if (!msg.isIncoming) {
            progressString = [NSString stringWithFormat:@"%@",
                              NSLocalizedString(@"conversation_message_info_sent", nil)];
        }

        if ([progressString length]) {
            attributedString = [[NSMutableAttributedString alloc] initWithString:@""];

            if (error) {
                [attributedString insertAttributedString:[[NSAttributedString alloc]
                                                          initWithString:progressString
                                                          attributes:@{NSForegroundColorAttributeName: [UIColor redColor],
                                                                       NSFontAttributeName: [UIFont systemFontOfSize:10.0]}]
                                                 atIndex:0];
            } else {
                [attributedString insertAttributedString:[[NSAttributedString alloc]
                                                          initWithString:progressString
                                                          attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:10.0]}]
                                                 atIndex:0];
            }
        }

        return attributedString;
    }

    return nil;
}

- (BOOL)shouldShowMessageStatusAtIndexPath:(NSIndexPath*)indexPath message:(YapMessage*)currentMessage
{
    if (currentMessage == nil) {
        currentMessage = [self messageAtIndexPath:indexPath];
    }

    if (currentMessage.delivered == statusDownloading || currentMessage.delivered == statusUploading
               || currentMessage.delivered == statusParseError) {
        return YES;
    } else if (currentMessage.isIncoming) {
        return NO;
    } else if (indexPath.item + 1 < [self.collectionView numberOfItemsInSection:indexPath.section]) {
        // At this point, is always sure that there is another message
        return ([self nextOutgoingMessage:indexPath]) ? NO : YES;
    }

    return YES;
}

-(BOOL)nextOutgoingMessage:(NSIndexPath*)indexPath
{
    YapMessage * nextMessage = [self messageAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
    return (nextMessage.isIncoming == NO) ? YES : NO;
}

#pragma mark - JSQMessagesCollectionViewDelegateFlowLayout Methods -

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return ([self showDateAtIndexPath:indexPath]) ? kJSQMessagesCollectionViewCellLabelHeightDefault : 0.0f;
}

- (BOOL)showDateAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return YES;
    } else {
        YapMessage *currentMessage = [self messageAtIndexPath:indexPath];
        YapMessage *previousMessage = [self messageAtIndexPath:[NSIndexPath indexPathForItem:indexPath.row - 1 inSection:indexPath.section]];

        NSCalendar *cal = [NSCalendar currentCalendar];
        NSDate *startOfToday, *startOfOtherDay;
        [cal rangeOfUnit:NSCalendarUnitDay startDate:&startOfToday interval:NULL forDate:previousMessage.date];
        [cal rangeOfUnit:NSCalendarUnitDay startDate:&startOfOtherDay interval:NULL forDate:currentMessage.date];
        NSDateComponents *components = [cal components:NSCalendarUnitDay fromDate:startOfOtherDay toDate:startOfToday options:0];
        NSInteger days = labs([components day]);

        NSTimeInterval distanceBetweenDates = [currentMessage.date timeIntervalSinceDate:previousMessage.date];
        double minutesBetweenDates = fabs(distanceBetweenDates / 1200); // Seconds past in 20 minutes

        return ((days >= 1) || (minutesBetweenDates >= 1) || (indexPath.row != 1 && indexPath.row % 20 == 0)) ? YES : NO;
    }

    return NO;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath {
    return ([self shouldShowMessageStatusAtIndexPath:indexPath message:nil]) ? 16.0f : 0.0f;
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    if ([self shouldShowLoadEarlierMessages]) {
        self.page++;
    }

    NSInteger item = (NSInteger)[self scrollToItem];

    [self updateRangeOptionsForPage:self.page];

    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        [self.messageMappings updateWithTransaction:transaction];
    }];

    [self updateLayoutForEarlierMessagesWithOffset:item];
}

-(NSUInteger)scrollToItem
{
    __block NSUInteger item = kYapDatabaseRangeLength*(self.page+1) - [self.messageMappings numberOfItemsInGroup:self.buddy.uniqueId];

    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {

        NSUInteger numberOfVisibleMessages = [self.messageMappings numberOfItemsInGroup:self.buddy.uniqueId] ;
        NSUInteger numberOfTotalMessages = [[transaction ext:ChatDatabaseViewExtensionName] numberOfItemsInGroup:self.buddy.uniqueId] ;
        NSUInteger numberOfMessagesToLoad =  numberOfTotalMessages - numberOfVisibleMessages ;

        BOOL canLoadFullRange = numberOfMessagesToLoad >= kYapDatabaseRangeLength;

        if (!canLoadFullRange) {
            item = numberOfMessagesToLoad;
        }
    }];

    return item == 0 ? item : item - 1;
}

-(void)updateLayoutForEarlierMessagesWithOffset:(NSInteger)offset
{
    [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
    // Get older messages and add to collectionView
    [self reloadData];
    // Scroll to the last index showed
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:offset inSection:0] atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    // Decide if should show "Load earlier messages"
    [self updateLoadEarlierVisible];
}

-(void)updateLoadEarlierVisible
{
    [self setShowLoadEarlierMessagesHeader:[self shouldShowLoadEarlierMessages]];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = self.messages[indexPath.item];
    YapMessage *msg = [self messageAtIndexPath:indexPath];
    
    if (msg.getStatus == statusParseError) {
        [self handleUnsentMessageTap:msg jsqMessage:message];
    } else {
        if (message.isMediaMessage) {
            if ([message.media isKindOfClass:[PhotoMediaItem class]]) {
                PhotoMediaItem *mediaItem = (PhotoMediaItem *)message.media;
                if (mediaItem.status == STATUS_FAILED) {
                    
                } else if (mediaItem.status == STATUS_SUCCEED) {
                    NSArray *photos = [IDMPhoto photosWithImages:@[mediaItem.image]];
                    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
                    [self presentViewController:browser animated:YES completion:nil];
                }
            } else if ([message.media isKindOfClass:[VideoMediaItem class]]) {
                VideoMediaItem *mediaItem = (VideoMediaItem *)message.media;
                if (mediaItem.status == STATUS_FAILED) {
                
                } else if (mediaItem.status == STATUS_SUCCEED) {
                    [self playMediaWithURL:mediaItem.fileURL];
                }
            } else if ([message.media isKindOfClass:[JSQLocationMediaItem class]]) {
                JSQLocationMediaItem *mediaItem = (JSQLocationMediaItem *)message.media;
                MapView *mapView = [[MapView alloc] initWith:mediaItem.location];
                UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mapView];
                [self presentViewController:navController animated:YES completion:nil];
            } else if([message.media isKindOfClass:[AudioMediaItem class]]) {
                AudioMediaItem *mediaItem = (AudioMediaItem *)message.media;
                if (mediaItem.status == STATUS_FAILED) {

                } else if (mediaItem.status == STATUS_SUCCEED) {
                    [self playMediaWithURL:mediaItem.fileURL];
                }
            }
        }
    }
}


#pragma mark - JSQMessagesComposerTextViewPasteDelegate Method -

- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender {
    if ([UIPasteboard generalPasteboard].image) {
        // If there's an image in the pasteboard, show view asking if the user wants to send it
        return NO;
    }
    return YES;
}

# pragma mark - ConversationListener Methods

- (void)messageReceived:(YapMessage *)message from:(YapContact *)from {
    if ([self.buddy.uniqueId isEqualToString:from.uniqueId]) {
        message.view = YES;
        message.read = YES;

        [self.messageDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            [message saveWithTransaction:transaction];
            [self.buddy saveWithTransaction:transaction];
        } completionBlock:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_CELL_NOTIFICATION_NAME
                                                                object:nil
                                                              userInfo:@{UPDATE_CELL_DIC_KEY: self.buddy.uniqueId}];
        }];
    } else {
        if ([SettingsKeys getNotificationPreviewInApp:YES]) {
            NSString *text = nil;

            switch (message.messageType) {
                case kMessageTypeText: {
                    text = message.text;
                    break;
                }
                case kMessageTypeLocation: {
                    text = NSLocalizedString(@"chats_cell_conversation_location", nil);
                    break;
                }
                case kMessageTypeVideo: {
                    text = NSLocalizedString(@"chats_cell_conversation_video", nil);
                    break;
                }
                case kMessageTypeAudio: {
                    text = NSLocalizedString(@"chats_cell_conversation_audio", nil);
                    break;
                }
                case kMessageTypeImage: {
                    text = NSLocalizedString(@"chats_cell_conversation_image", nil);
                    break;
                }
                default: {
                    text = NSLocalizedString(@"chats_cell_conversation_message", nil);
                    break;
                }
            }

            if ([SettingsKeys getNotificationSoundInApp:YES]) {
                NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"sound_notification_manager" ofType:@"mp3"];
                CFURLRef cfString = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:soundPath]);
                SystemSoundID soundID;
                AudioServicesCreateSystemSoundID(cfString, &soundID);
                AudioServicesPlaySystemSound (soundID);
                CFRelease(cfString);
            }

            [[WhisperBridge sharedInstance] shout:from.displayName
                                         subtitle:text
                                  backgroundColor:[UIColor clearColor]
                           toNavigationController:self.navigationController
                                            image:nil
                                     silenceAfter:1.8
                                           action:nil];
        }
//        YapDatabaseConnection *connection = [[DatabaseManager sharedInstance] newConnection];
//        [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
//         {
//             [message saveWithTransaction:transaction];
//             from.lastMessageDate = message.date;
//             [from saveWithTransaction:transaction];
//         } completionBlock:^{
//             if ([SettingsKeys getNotificationPreviewInApp:YES]) {
//                 NSString *text = nil;
//
//                 switch (message.messageType) {
//                     case kMessageTypeText: {
//                         text = message.text;
//                         break;
//                     }
//                     case kMessageTypeLocation: {
//                         text = NSLocalizedString(@"chats_cell_conversation_location", nil);
//                         break;
//                     }
//                     case kMessageTypeVideo: {
//                         text = NSLocalizedString(@"chats_cell_conversation_video", nil);
//                         break;
//                     }
//                     case kMessageTypeAudio: {
//                         text = NSLocalizedString(@"chats_cell_conversation_audio", nil);
//                         break;
//                     }
//                     case kMessageTypeImage: {
//                         text = NSLocalizedString(@"chats_cell_conversation_image", nil);
//                         break;
//                     }
//                     default: {
//                         text = NSLocalizedString(@"chats_cell_conversation_message", nil);
//                         break;
//                     }
//                 }
//
//                 if ([SettingsKeys getNotificationSoundInApp:YES]) {
//                     NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"sound_notification_manager" ofType:@"mp3"];
//                     CFURLRef cfString = (CFURLRef)CFBridgingRetain([NSURL fileURLWithPath:soundPath]);
//                     SystemSoundID soundID;
//                     AudioServicesCreateSystemSoundID(cfString, &soundID);
//                     AudioServicesPlaySystemSound (soundID);
//                     CFRelease(cfString);
//                 }
//
//                 [[WhisperBridge sharedInstance] shout:from.displayName
//                                              subtitle:text
//                                       backgroundColor:[UIColor clearColor]
//                                toNavigationController:self.navigationController
//                                                 image:nil
//                                          silenceAfter:1.8
//                                                action:nil];
//             }
//         }];
    }
}

- (void)fromUser:(NSString*)contactId userIsTyping:(BOOL)isTyping {
    if ([self.buddy.uniqueId isEqualToString:contactId]) {
        if (self.timeWaiting) {
            [self.timeWaiting invalidate];
            self.timeWaiting = nil;
        }

        if (isTyping) {
            self.timeWaiting = [NSTimer scheduledTimerWithTimeInterval:6
                                                                target:self
                                                              selector:@selector(showIsTyping:)
                                                              userInfo:@(NO)
                                                               repeats:NO];
        }

        [self showIsTyping:isTyping];
    }
}

- (void)showIsTyping:(BOOL)show {
    if (show) {
        self.subTitle.hidden = NO;
        self.subTitle.text = NSLocalizedString(@"conversation_subtitle_writing", nil);
    } else {
        self.subTitle.hidden = YES;
    }
}

- (void)receivedTextViewChangedNotification:(NSNotification *)notification
{
    if (!self.buddy.blocked) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self];

        if ([self.inputToolbar.contentView.textView hasText]) {
            if (!self.typingFlag) {
                NSLog(@"Try to send typing started update");
                self.typingFlag = YES;
                [[CustomAblyRealtime sharedInstance] sendTypingStateOnChannel:[self.buddy getPublicChannel]
                                                                     isTyping:YES];
            }

            [self performSelector:@selector(userHasEndedTyping)
                       withObject:self
                       afterDelay:kWaitingTimeInSeconds];
        } else {
            [self performSelector:@selector(userHasEndedTyping)
                       withObject:self
                       afterDelay:0];
        }
    }
}

- (void)userHasEndedTyping {
    NSLog(@"Try to send typing ended update");
    self.typingFlag = NO;
    [[CustomAblyRealtime sharedInstance] sendTypingStateOnChannel:[self.buddy getPublicChannel]
                                                         isTyping:NO];
}

#pragma mark - Actions Methods -

- (IBAction)goToProfile:(id)sender {
    // TODO: Implement action for profile tap
}

- (void)showUnblockMessage {
    UIAlertController* view = [UIAlertController
                                alertControllerWithTitle:nil
                                message:NSLocalizedString(@"conversation_alert_action_unblock_title", nil)
                                preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* unblock = [UIAlertAction actionWithTitle:NSLocalizedString(@"conversation_alert_action_unblock", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * action)
    {
        self.buddy.blocked = NO;
        [self.editingDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
        {
            [self.buddy saveWithTransaction:transaction];
        }];
        
        [view dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"common_action_cancel", nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action)
    {
        [view dismissViewControllerAnimated:YES completion:nil];
    }];
        
    [view addAction:unblock];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

- (void)actionCopy:(NSIndexPath *)indexPath {
    YapMessage *message = [self messageAtIndexPath:indexPath];
    [[UIPasteboard generalPasteboard] setString:message.text];
}

- (void)actionDelete:(NSIndexPath *)indexPath {
    YapMessage *message = [self messageAtIndexPath:indexPath];
    [self.editingDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [message removeWithTransaction:transaction];
    }];
}

- (void)playMediaWithURL:(NSURL*)mediaUrl {
    // Create an AVPlayer
    AVPlayer *moviePlayer = [AVPlayer playerWithURL:mediaUrl];
    // Option: 1
//    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:mediaUrl];
//    moviePlayer = [AVPlayer playerWithPlayerItem:playerItem];
//    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:moviePlayer];
//    layer.frame = CGRectMake(0, 0, 320 , 480);
//    [self.view.layer addSublayer: layer];
//    moviePlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
//    [moviePlayer play];
    // Option 2
    // Create a player view controller
    AVPlayerViewController *controller = [[AVPlayerViewController alloc]init];
    // Show the view controller
    controller.view.frame = self.view.frame;
    [self presentViewController:controller animated:YES completion:nil];
    // Play
    controller.player = moviePlayer;
    moviePlayer.closedCaptionDisplayEnabled = NO;
    moviePlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    [moviePlayer play];
}

#pragma mark - Send messages Methods -

- (void)sendLocation {
    if([NotificationPermissions checkPermissions:self]) {
        __weak typeof(self)weakSelf = self;
        [PFGeoPoint geoPointForCurrentLocationInBackground:^(PFGeoPoint *geoPoint, NSError *error) {
            typeof(weakSelf)sSelf = weakSelf;
            if (error == nil) {
                if (sSelf) {
                    YapMessage *message = [self newYapMessageType:kMessageTypeLocation
                                                           values:@{MESSAGE_LATI_KEY:[NSNumber numberWithDouble:geoPoint.latitude],
                                                                    MESSAGE_LONG_KEY:[NSNumber numberWithDouble:geoPoint.longitude]}
                                                         incoming:NO];
                    message.transferProgress = 100;
                    [sSelf sendWithYapMessage:message isLastMessage:YES withPFFile:nil];
                }
            } else {
                if (sSelf) {
                    UIAlertController* view = [UIAlertController
                                               alertControllerWithTitle:NSLocalizedString(@"conversation_alert_action_location_title", nil)
                                               message:nil
                                               preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* ok = [UIAlertAction
                                         actionWithTitle:@"Ok"
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action) {
                                             [view dismissViewControllerAnimated:YES completion:nil];
                                         }];
                    
                    [view addAction:ok];
                    [weakSelf presentViewController:view animated:YES completion:nil];
                }
            }
        }];
    }
}

- (void)sendWithYapMessage:(YapMessage *)yapMessage isLastMessage:(BOOL)isLastMessage withPFFile:(PFFile *)file
{
    YapMessage *message = [yapMessage copy];
    
    if (!isLastMessage) {
        // Update message date to show as newer message sent
        message.date = [NSDate date];
    }

    [self.editingDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [message saveWithTransaction:transaction];
        self.buddy.lastMessageDate = message.date;
        [self.buddy saveWithTransaction:transaction];
    } completionBlock:^{
        if (message.getStatus == statusUploading || message.getStatus == statusParseError)
        {
            NSMutableDictionary *messageNSD = [NSMutableDictionary dictionaryWithDictionary:
                                               @{
                                                 @"customerId" : self.buddy.uniqueId,
                                                 @"businessId" : [SettingsKeys getBusinessId],
                                                 @"messageType" : [NSNumber numberWithInteger:yapMessage.messageType]
                                                 }];

            NSString *connectionId = [[CustomAblyRealtime sharedInstance] getPublicConnectionId];
            if (connectionId) {
                [messageNSD addEntriesFromDictionary:@{@"connectionId" : connectionId}];
            }

            switch (yapMessage.messageType) {
                case kMessageTypeText: {
                    [messageNSD addEntriesFromDictionary:@{@"text" : message.text}];
                    break;
                }
                case kMessageTypeLocation: {
                    [messageNSD addEntriesFromDictionary:@{
                                                           @"latitude": [NSNumber numberWithDouble:message.location.coordinate.latitude],
                                                           @"longitude": [NSNumber numberWithDouble:message.location.coordinate.longitude]}];
                    break;
                }
                case kMessageTypeImage: {
                    [messageNSD addEntriesFromDictionary:@{
                                                           @"size": [NSNumber numberWithCGFloat:message.bytes],
                                                           @"width" : [NSNumber numberWithCGFloat:message.width],
                                                           @"height": [NSNumber numberWithCGFloat:message.height],
                                                           @"file": file}];
                    break;
                }
            }

            [PFCloud callFunctionInBackground:@"sendUserMessage"
                               withParameters:messageNSD
                                        block:^(id  _Nullable object, NSError * _Nullable error)
             {
                 if(error) {
                     if ([ParseValidation validateError:error]) {
                         self.visible = NO;
                         [ParseValidation _handleInvalidSessionTokenError:self];
                         return;
                     } else {
                         DDLogError(@"Message sent error: %@", error.localizedDescription);
                         message.delivered = statusParseError;
                         message.error = error.localizedDescription;
                     }
                 } else {
                     message.delivered = statusAllDelivered;
                     message.error = nil;
                 }

                 [self.editingDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
                  {
                      [message saveWithTransaction:transaction];
                  }];
             }];
        }

        if (!self.checkIfAlreadyAdded) {
            // Notify observers a user was added
            self.checkIfAlreadyAdded = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_CHATS_NOTIFICATION_NAME
                                                                object:nil
                                                              userInfo:nil];
        }
    }];
}

#pragma mark - UIImagePickerControllerDelegate Method -

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *picture = compressImage(info[UIImagePickerControllerEditedImage], NO);
        
    // Set visible so YapNotification don't skip UI updates
    self.visible = true;
        
    [self processImage:picture];
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingItems:(NSArray *)items
{
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    // Set visible so YapNotification don't skip UI updates
    self.visible = true;
    
    if ([items count]) {
        PHImageManager *manager = [PHImageManager defaultManager];
        [self recursiveImageProcessing:[items copy] position:0 manager:manager];
    }
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)recursiveImageProcessing:(NSArray *)items position:(int)position manager:(PHImageManager *)manager {
    if (position < [items count]) {        
        PHAsset *asset = (PHAsset *)[items objectAtIndex:position];
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeFastFormat;
        options.synchronous = NO;
        options.networkAccessAllowed = NO;
        options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
            NSLog(@"%f", progress); //follow progress + update progress bar
        };
        
        [manager requestImageDataForAsset:asset
                                  options:options
                            resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info)
         {
             if (imageData) {
                 [self processImage:compressImage([UIImage imageWithData:imageData], NO)];
//                 [self recursiveImageProcessing:items position:(position + 1) manager:manager];
             }
         }];
    }
}

- (void)processImage:(UIImage *)picture {
    NSString *imageName = GetImageName();
    NSData *imageData = UIImageJPEGRepresentation(picture, 0.4);
    // Save to Cache Directory
    [[NSFileManager defaultManager] saveDataToLibraryDirectory:imageData
                                                      withName:imageName
                                                  andDirectory:kMessageMediaImageLocation];
    // Create message
    __block YapMessage *message = [self newYapMessageType:kMessageTypeImage
                                                   values:@{MESSAGE_FILENAME_KEY: imageName,
                                                            MESSAGE_SIZE_KEY: [NSNumber numberWithUnsignedInteger:imageData.length]}
                                                 incoming:NO];

    message.width = picture.size.width;
    message.height = picture.size.height;
    message.filename = imageName;
    
    // Save so message can be inserted in collectionView
    [self.editingDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [message saveWithTransaction:transaction];
        self.buddy.lastMessageDate = message.date;
        [self.buddy saveWithTransaction:transaction];
    }];
    
    // Try to upload message
    PFFile *filePicture = [PFFile fileWithName:imageName data:imageData];
    [filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (error == nil) {
            message.transferProgress = 100;
            [self sendWithYapMessage:message isLastMessage:YES withPFFile:filePicture];
        } else {
            // Couldn't send image
            message.delivered = statusParseError;
            message.transferProgress = 0;
            message.error = error.localizedDescription;
            
            [self.editingDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction)
             {
                 [message saveWithTransaction:transaction];
             }];
        }
    } progressBlock:^(int percentDone) {
        message.transferProgress = percentDone;
        [self.editingDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
         {
             [message saveWithTransaction:transaction];
         }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // Set visible so YapNotification don't skip UI updates
    self.visible = true;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)image:(UIImage *)image finishedSavingWithError:(NSError *) error contextInfo:(void *)contextInfo {
    // Set visible so YapNotification don't skip UI updates
    self.visible = true;
    if (error) {
        UIAlertController* view = [UIAlertController
                                   alertControllerWithTitle:NSLocalizedString(@"conversation_alert_action_camara_title", nil)
                                   message:nil
                                   preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction
                                 actionWithTitle:@"Ok"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action) {
                                     [view dismissViewControllerAnimated:YES completion:nil];
                                 }];
        
        [view addAction:ok];
        [self presentViewController:view animated:YES completion:nil];
    }
}

#pragma mark - YapDatabase Methods -

-(BOOL)shouldShowLoadEarlierMessages {
    __block BOOL show = YES;

    [self.databaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction){
        show = [self.messageMappings numberOfItemsInGroup:self.buddy.uniqueId] < [[transaction ext:ChatDatabaseViewExtensionName] numberOfItemsInGroup:self.buddy.uniqueId];
    }];

    return show;
}

-(void)updateRangeOptionsForPage:(NSUInteger)page {
    YapDatabaseViewRangeOptions *rangeOptions = [YapDatabaseViewRangeOptions flexibleRangeWithLength:kYapDatabaseRangeLength*(page+1) offset:0 from:YapDatabaseViewEnd];
    
    rangeOptions.maxLength = kYapDatabaseRangeMaxLength;
    rangeOptions.minLength = kYapDatabaseRangeMinLength;
    
    [self.messageMappings setRangeOptions:rangeOptions forGroup:self.buddy.uniqueId];
}

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Jump to the most recent commit.
    // End & Re-Begin the long-lived transaction atomically.
    // Also grab all the notifications for all the commits that I jump.
    // If the UI is a bit backed up, I may jump multiple commits.
    NSArray *notifications  = [self.databaseConnection beginLongLivedReadTransaction];
    
    if (self.messageMappings == nil) {
        [self setupMessageMapping];
        return;
    }
    
    if ([notifications count] <= 0) {
        // Since we moved our databaseConnection to a new commit,
        // we need to update the mappings too.
        [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
            [self.messageMappings updateWithTransaction:transaction];
        }];
        return; // Already processed commit
    }
    
    // If the view isn't visible, we might decide to skip the UI animation stuff.
    if (!self.visible) {
        // Since we moved our databaseConnection to a new commit,
        // we need to update the mappings too.
        [self.databaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction){
            [self.messageMappings updateWithTransaction:transaction];
        }];
        return;
    }

    NSArray *messageRowChanges = nil;

    [[self.databaseConnection ext:ChatDatabaseViewExtensionName] getSectionChanges:nil
                                                                        rowChanges:&messageRowChanges
                                                                  forNotifications:notifications
                                                                      withMappings:self.messageMappings];

    if([messageRowChanges count] == 0) {
        return;
    }
    
    __block BOOL isIncoming  = NO;
    __block BOOL isInserting = NO;
    BOOL shouldReloadMedia   = NO;
    
    //Look for my extended info
    for (NSNotification *notification in notifications) {
        NSDictionary *transactionExtendedInfo = [notification.userInfo objectForKey:YapDatabaseCustomKey];
        if (transactionExtendedInfo) {
            if (transactionExtendedInfo[YapDatabaseModifiedNotificationUpdate]) {
                shouldReloadMedia = YES;
            }
        }
    }

    [self.collectionView performBatchUpdates:^{
        for (YapDatabaseViewRowChange *rowChange in messageRowChanges)
        {
            switch (rowChange.type)
            {
                case YapDatabaseViewChangeDelete :
                {
                    [self.messages removeObjectAtIndex:rowChange.indexPath.row];
                    [self.collectionView deleteItemsAtIndexPaths:@[rowChange.indexPath]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_CELL_NOTIFICATION_NAME
                                                                        object:nil
                                                                      userInfo:@{UPDATE_CELL_DIC_KEY: self.buddy.uniqueId}];
                    break;
                }
                case YapDatabaseViewChangeInsert :
                {
                    YapMessage *message = [self messageAtIndexPath:rowChange.newIndexPath];
                    
                    if (message) {
                        Incoming *incoming = [[Incoming alloc] init];
                        JSQMessage *newMessage = [incoming create:message];
                        [self.messages addObject:newMessage];
                        
                        if (message.isIncoming)
                            isIncoming = YES;
                        
                        isInserting = YES;
                    }
                    
                    [self.collectionView insertItemsAtIndexPaths:@[rowChange.newIndexPath]];
                    break;
                }
                case YapDatabaseViewChangeMove :
                {
                    [self.collectionView moveItemAtIndexPath:rowChange.indexPath toIndexPath:rowChange.newIndexPath];
                    break;
                }
                case YapDatabaseViewChangeUpdate :
                {                    
                    if (shouldReloadMedia) {
                        YapMessage *message = [self messageAtIndexPath:rowChange.indexPath];
                        Incoming *incoming = [[Incoming alloc] init];
                        JSQMessage *msg = [incoming create:message];
                        [self.messages replaceObjectAtIndex:rowChange.indexPath.item withObject:msg];
                    }
                    
                    [self.collectionView reloadItemsAtIndexPaths:@[rowChange.indexPath]];
                    break;
                }
            }
        }
    } completion:^(BOOL success) {
            if (isInserting) {
                if (isIncoming) {
                    [self finishReceivingMessage];
                    self.subTitle.hidden = YES;
                    if ([SettingsKeys getMessageSoundIncoming:YES]) {
                        //[JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                    }
                } else {
                    [self finishSendingMessage];
                    if ([SettingsKeys getMessageSoundIncoming:NO]) {
                        //[JSQSystemSoundPlayer jsq_playMessageSentSound];
                    }
                }
            }
    }];
}

- (void)handleUnsentMessageTap:(YapMessage*)message jsqMessage:(JSQMessage*)jMessage {
    YapMessage *msg         = [message copy];
    JSQMessage *jsqMessage  = [jMessage copy];
    
    UIAlertController* view = [UIAlertController
                               alertControllerWithTitle:nil
                               message:nil
                               preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (jsqMessage.isMediaMessage) {
        if ([jsqMessage.media isKindOfClass:[PhotoMediaItem class]]) {
            UIAlertAction* photo = [UIAlertAction
                                     actionWithTitle:NSLocalizedString(@"conversation_unsent_alert_action_view", nil)
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * action) {
                                         PhotoMediaItem *mediaItem = (PhotoMediaItem *)jsqMessage.media;
                                         NSArray *photos = [IDMPhoto photosWithImages:@[mediaItem.image]];
                                         IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
                                         [view dismissViewControllerAnimated:YES completion:nil];
                                         [self presentViewController:browser animated:YES completion:nil];
                                     }];
            [view addAction:photo];
        } else if ([jsqMessage.media isKindOfClass:[JSQLocationMediaItem class]]) {
            UIAlertAction* location = [UIAlertAction
                                    actionWithTitle:NSLocalizedString(@"conversation_unsent_alert_action_map", nil)
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                        JSQLocationMediaItem *mediaItem = (JSQLocationMediaItem *)jsqMessage.media;
                                        MapView *mapView = [[MapView alloc] initWith:mediaItem.location];
                                        mapView.title = NSLocalizedString(@"mapview_controller_title", nil);
                                        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mapView];
                                        [view dismissViewControllerAnimated:YES completion:nil];
                                        [self presentViewController:navController animated:YES completion:nil];
                                    }];
            [view addAction:location];
        } else if([jsqMessage.media isKindOfClass:[AudioMediaItem class]]) {
            UIAlertAction* audio = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"conversation_unsent_alert_action_play", nil)
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action) {
                                           AudioMediaItem *mediaItem = (AudioMediaItem *)jsqMessage.media;
                                           [self playMediaWithURL:mediaItem.fileURL];
                                       }];
            [view addAction:audio];
            
        }
    }
    
    UIAlertAction* resend = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"conversation_unsent_alert_action_resend", nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       // Retry
                                       [self sendWithYapMessage:msg isLastMessage:NO withPFFile:nil];
                                       [view dismissViewControllerAnimated:YES completion:nil];
                                   }];
    UIAlertAction* delete = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"conversation_unsent_alert_action_delete", nil)
                             style:UIAlertActionStyleDestructive
                             handler:^(UIAlertAction * action) {
                                 [self.editingDatabaseConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
                                     [msg removeWithTransaction:transaction];
                                 }];
                                 [view dismissViewControllerAnimated:YES completion:nil];
                             }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"common_action_cancel", nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action) {
                                 [view dismissViewControllerAnimated:YES completion:nil];
                             }];
    
    [view addAction:resend];
    [view addAction:delete];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

@end
