
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

@import YapDatabase;
@import MediaPlayer;
@import AVFoundation;
#import "Log.h"
#import "Image.h"
#import "Camera.h"
#import "Colors.h"
#import "AppJobs.h"
#import "MapView.h"
#import "Message.h"
#import "Incoming.h"
#import "Business.h"
#import "Constants.h"
#import "Utilities.h"
#import "YapContact.h"
#import "YapMessage.h"
#import "SettingsKeys.h"
#import "DatabaseView.h"
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

#define kYapDatabaseRangeLength    25
#define kYapDatabaseRangeMaxLength 300
#define kYapDatabaseRangeMinLength 20
#define kInputToolbarMaximumHeight 150
#define kWaitingTimeInSeconds 3

@interface ConversationViewController ()

@property (nonatomic, strong) YapDatabaseConnection *databaseConnection;
@property (nonatomic, strong) YapDatabaseConnection *editingDatabaseConnection;
@property (nonatomic, strong) YapDatabaseConnection *messageDatabaseConnection;

@property (nonatomic, strong) YapDatabaseViewMappings *messageMappings;

@property (nonatomic, strong) JSQMessagesBubbleImage *outgoingBubbleImage;
@property (nonatomic, strong) JSQMessagesBubbleImage *incomingBubbleImage;

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) UILabel *titleView;
@property (nonatomic, strong) UILabel *subTitle;

@property (nonatomic) NSUInteger page;

@property(nonatomic) BOOL visible;

@property(nonatomic,weak) NSTimer* timeWaiting;

@end

@implementation ConversationViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.messages = [[NSMutableArray alloc] init];
    
    // Bar tint
    self.navigationController.navigationBar.barTintColor = [Colors whiteColor];
    
    // JSQMessagesController variables setup
    self.senderId = ([[SettingsKeys getBusinessId] length] == 0) ? @"" : [SettingsKeys getBusinessId];
    self.senderDisplayName = @"user";

    /**
     *  Set up message accessory button delegate and configuration
     */
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
    self.navigationController.navigationBar.barTintColor = [Colors whiteNavbarColor];
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
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self saveCurrentMessageText];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.visible = false;
}

- (void)willMoveToParentViewController:(UIViewController *)parent {
    [super willMoveToParentViewController:parent];
    if (parent == nil) {
        UIViewController *last = [self.navigationController.viewControllers firstObject];
        if (last) {
            if ([last isKindOfClass:[ChatsViewController class]]) {
                self.navigationController.navigationBar.barTintColor = [Colors purpleNavbarColor];
                self.navigationController.navigationBar.tintColor = [Colors whiteColor];
            }
        }
    }
}

#pragma mark - Setup Methods -

- (void)loadNavigationBarInformation {
//    __weak typeof(self) wSelf = self;
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
//        UIImage *image = [[NSFileManager defaultManager] loadAvatarFromLibrary:[self.buddy.uniqueId stringByAppendingString:@"_avatar.jpg"]];
//        
//        // When finished call back on the main thread:
//        dispatch_async(dispatch_get_main_queue(), ^{
//            typeof(self)sSelf = wSelf;
//            if (sSelf) {
//                UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,38,38)];
//
//                if (image) {
//                    logo.image = image;
//                } else {
//                    [logo sd_setImageWithURL:[NSURL URLWithString:self.buddy.avatarThumbFileId]
//                            placeholderImage:[UIImage imageNamed:@"ic_business_default"]];
//                }
//
//                logo.layer.cornerRadius = 19;
//                logo.layer.masksToBounds = YES;
//                
//                UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:sSelf action:@selector(logoTapped:)];
//                singleTap.numberOfTapsRequired = 1;
//                [logo setUserInteractionEnabled:YES];
//                [logo addGestureRecognizer:singleTap];
//                
//                sSelf.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:logo];
//            }
//        });
//    });

    self.navigationController.navigationBar.topItem.title = NSLocalizedString(@"conversation_navigation_title", nil);

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 175, 20)];
    title.textAlignment = NSTextAlignmentCenter;
    [title setText:self.buddy.displayName];
    [title setNumberOfLines:1];
    title.lineBreakMode = NSLineBreakByTruncatingTail;
    [title setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
    self.titleView = title;
    
    UILabel *subTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 25, 175, 10)];
    subTitle.textAlignment = NSTextAlignmentCenter;
    [subTitle setText:@""];
    [subTitle setNumberOfLines:1];
    subTitle.lineBreakMode = NSLineBreakByTruncatingTail;
    [subTitle setFont:[UIFont fontWithName:@"HelveticaNeue" size:12]];
    [subTitle setTextColor:[UIColor lightGrayColor]];
    self.subTitle = subTitle;
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 175, 40)];
    [view addSubview:title];
    [view addSubview:subTitle];
    
    UITapGestureRecognizer *profileTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(goToProfile:)];
    profileTap.numberOfTapsRequired = 1;
    [view setUserInteractionEnabled:YES];
    [view addGestureRecognizer:profileTap];
    
    self.navigationItem.titleView = view;
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
            [self updateRangeOptionsForPage:self.page];
            
            [self.editingDatabaseConnection asyncReadWithBlock:^(YapDatabaseReadTransaction *transaction) {
                [self.messageMappings updateWithTransaction:transaction];
                [self loadData];
            }];
            
            [self loadNavigationBarInformation];
        }
    }
    
    // Update reference
    self.buddy = buddy;
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
    self.outgoingBubbleImage = [bubbleImageFactory outgoingMessagesBubbleImageWithColor:[Colors outgoingColor]];
    self.incomingBubbleImage = [bubbleImageFactory incomingMessagesBubbleImageWithColor:[Colors incomingColor]];
    // No avatars
    self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
}

- (void)initializeInputToolbar {
    // Set a maximum height for the input toolbar
    self.inputToolbar.maximumHeight = kInputToolbarMaximumHeight;
    // The library will call the correct selector for each button, based on this value
    self.inputToolbar.sendButtonOnRight = YES;
    // Attachment Button
    UIButton *customLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    customLeftButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    customLeftButton.frame = CGRectMake(0, 0, 30, 30);
    UIImage * buttonImage = [UIImage imageNamed:@"ic_attachment"];
    [customLeftButton setContentMode:UIViewContentModeScaleAspectFit];
    [customLeftButton setBackgroundImage:buttonImage forState:UIControlStateNormal];
    self.inputToolbar.contentView.leftBarButtonItem = customLeftButton;

    UIButton *customRightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    customRightButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    customRightButton.backgroundColor = [UIColor clearColor];
    customRightButton.frame = CGRectMake(0, 0, 32, 32);
    customRightButton.layer.cornerRadius = customRightButton.frame.size.width / 2;
    UIImage * sendImage = [UIImage imageNamed:@"ic_send"];
    [customRightButton setContentMode:UIViewContentModeScaleAspectFit];
    [customRightButton setBackgroundImage:sendImage forState:UIControlStateNormal];
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
        
        UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"conversation_more_alert_action_cancel", nil)
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
        cell.textView.textColor = [Colors blackColor];
        cell.textView.dataDetectorTypes = UIDataDetectorTypeAll;
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : [Colors blackColor],
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

    if(msg.messageType != kMessageTypeText) {

        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@""];;
        NSString *progressString = nil;

        if (msg.isIncoming) {
            if (msg.transferProgress == 100) {
                return [self checkDelivered:indexPath andMessage:msg];
            } else if(msg.transferProgress > 0) {
                progressString = [NSString stringWithFormat:@"%@ %i%%", NSLocalizedString(@"conversation_message_info_received", nil), msg.transferProgress];
            } else {
                progressString = [NSString stringWithFormat:@"%@", NSLocalizedString(@"conversation_message_info_waiting", nil)];
            }
        } else {
            if (msg.transferProgress == 100) {
                return [self checkDelivered:indexPath andMessage:msg];
            } else if(msg.transferProgress > 0) {
                progressString = [NSString stringWithFormat:@"%@ %i%%", NSLocalizedString(@"conversation_message_info_sent", nil), msg.transferProgress];
            } else {
                if (msg.delivered == statusParseError) {
                    progressString = [NSString stringWithFormat:@"%@", NSLocalizedString(@"conversation_message_info_failed", nil)];
                } else {
                    progressString = [NSString stringWithFormat:@"%@", NSLocalizedString(@"conversation_message_info_waiting", nil)];
                }
            }
        }

        if ([progressString length]) {
            if (msg.delivered == statusParseError) {
                [attributedString insertAttributedString:[[NSAttributedString alloc]
                                                          initWithString:progressString
                                                          attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}]
                                                 atIndex:0];
            } else {
                [attributedString insertAttributedString:[[NSAttributedString alloc] initWithString:progressString]
                                                 atIndex:0];
            }
        }

        return attributedString;
    }

    return [self checkDelivered:indexPath andMessage:msg];
}

- (NSAttributedString*)checkDelivered:(NSIndexPath*)indexPath andMessage:(YapMessage*)msg
{
    if ([self shouldShowMessageStatusAtIndexPath:indexPath]) {
        NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
        textAttachment.bounds = CGRectMake(0, 0, 11.0f, 10.0f);
        
        if (msg.getStatus == statusParseError) {
            NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc]initWithString:NSLocalizedString(@"conversation_message_info_failed", nil)
                                                                                       attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}];
            [attrStr appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment]];
            return attrStr;
        }
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc]initWithString:NSLocalizedString(@"conversation_message_info_sent", nil)];
        [attrStr appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment]];
        
        return attrStr;
    }
    
    return nil;
}

- (BOOL)shouldShowMessageStatusAtIndexPath:(NSIndexPath*)indexPath
{
    YapMessage *currentMessage = [self messageAtIndexPath:indexPath];

    if ( currentMessage.delivered == statusDownloading || currentMessage.delivered == statusUploading ||
         currentMessage.delivered == statusParseError
       ) {
        return YES;
    } else if (currentMessage.isIncoming || currentMessage.getStatus == statusReceived) {
        return NO;
    } else if (indexPath.item == [self.collectionView numberOfItemsInSection:indexPath.section] - 1) {
        // If is the last message and is outgoing, show message status
        return (currentMessage.isIncoming == NO);
    }
    
    // At this point, is always sure that there is another message
    YapMessage *nextMessage = [self nextOutgoingMessage:indexPath];
    return (nextMessage) ? NO : YES;
}

-(YapMessage*)nextOutgoingMessage:(NSIndexPath*)indexPath
{
    YapMessage * nextMessage = [self messageAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section]];
    return (nextMessage.isIncoming == NO) ? nextMessage : nil;
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
        NSInteger days = [components day];

        NSTimeInterval distanceBetweenDates = [currentMessage.date timeIntervalSinceDate:previousMessage.date];
        NSInteger minutesBetweenDates = distanceBetweenDates / 900; // Seconds past in 15 minutes
        
        return ((days == -1) || (minutesBetweenDates >= 1)) ? YES : NO;
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
    return ([self shouldShowMessageStatusAtIndexPath:indexPath]) ? 16.0f : 0.0f;
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
                    MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:mediaItem.fileURL];
                    [self presentMoviePlayerViewControllerAnimated:moviePlayer];
                    [moviePlayer.moviePlayer play];
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
                    MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:mediaItem.fileURL];
                    [self presentMoviePlayerViewControllerAnimated:moviePlayer];
                    [moviePlayer.moviePlayer play];
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

- (void)messageReceived:(YapMessage *)message from:(YapContact *)from text:(NSString *)text {
    if (![self.buddy.uniqueId isEqualToString:from.uniqueId]) {
        [WhisperBridge shout:from.displayName
                    subtitle:text
             backgroundColor:[UIColor clearColor]
      toNavigationController:self.navigationController
                       image:nil
                silenceAfter:1.8
                      action:nil];
    } else {
        message.view = YES;
        message.read = YES;

        [self.messageDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            [message saveWithTransaction:transaction];
        } completionBlock:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_CELL_NOTIFICATION_NAME
                                                                object:nil
                                                              userInfo:@{UPDATE_CELL_DIC_KEY: self.buddy.uniqueId}];
        }];
        self.subTitle.hidden = YES;
    }
}

- (void)fromUser:(NSString*)contactId userIsTyping:(BOOL)isTyping {
    if ([self.buddy.uniqueId isEqualToString:contactId]) {
        if (isTyping) {
            self.subTitle.hidden = NO;
            self.subTitle.text = NSLocalizedString(@"conversation_subtitle_writing", nil);
        } else {
            self.subTitle.hidden = YES;
        }
    }
}

- (void)fromUser:(NSString*)objectId didGoOnline:(BOOL)status {
    if ([self.buddy.uniqueId isEqualToString:objectId]) {
        NSString *title = self.subTitle.text;
        
        if ([title isEqualToString:NSLocalizedString(@"conversation_subtitle_writing", nil)]) {
            title = self.buddy.displayName;
        }
        
        [NSTimer scheduledTimerWithTimeInterval:kWaitingTimeInSeconds
                                         target:self
                                       selector:@selector(updateOnline:)
                                       userInfo:title
                                        repeats:NO];
    }
}

-(void)updateOnline:(NSTimer *)timer {
    //Update Values in Label here
    self.subTitle.text = [timer userInfo];
    [timer invalidate];
    timer = nil;
}

#pragma mark - Actions Methods -

- (IBAction)logoTapped:(id)sender {
    // TODO: Implement action for logo tap
}

- (IBAction)goToProfile:(id)sender {
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    UINavigationController *navigationController1 = [storyboard instantiateViewControllerWithIdentifier:@"profileNavigationController"];
//    navigationController1.modalPresentationStyle = UIModalPresentationFormSheet;
//    navigationController1.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
//    ProfileViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"ProfileViewController"];
//    
//    // Create object business without reference
//    Business *bs = [Business objectWithoutDataWithObjectId:self.buddy.uniqueId];
//    NSData *data = UIImageJPEGRepresentation([[NSFileManager defaultManager] loadImageFromLibrary:[self.buddy.uniqueId stringByAppendingString:@"_avatar.jpg"]], 1);
//
//    if (data) {
//        bs.avatar = [PFFile fileWithData:data];
//    }
//
//    bs.displayName = self.buddy.displayName;
//    bs.conversaID = self.buddy.conversaId;
//    
//    vc.business = bs;
//    [navigationController1 setViewControllers:@[vc] animated:YES];
//    [self presentViewController:navigationController1 animated:YES completion:nil];
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
    
    UIAlertAction* cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"conversation_alert_action_unblock_cancel", nil)
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action)
    {
        [view dismissViewControllerAnimated:YES completion:nil];
    }];
        
    [view addAction:unblock];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}


- (void)receivedTextViewChangedNotification:(NSNotification *)notification
{
    if (!self.buddy.blocked) {
        // Wait before send another typing state or if the view isn't visible,
        // we might decide to skip the UI animation stuff.
        if (self.timeWaiting || !self.visible)
            return;
        
        NSMutableDictionary *cb = [[NSMutableDictionary alloc] init];
        [cb setObject:[self.inputToolbar.contentView.textView text] forKey:@"text"];
        self.timeWaiting = [NSTimer scheduledTimerWithTimeInterval:kWaitingTimeInSeconds
                                                            target:self
                                                          selector:@selector(handleTimer:)
                                                          userInfo:cb
                                                           repeats:NO];
    
        if ([self.inputToolbar.contentView.textView hasText]) {
            //[[PubNubService sharedInstance] sendTypingStateOnChannel:[self.buddy getPrivateChannel] isTyping:YES];
        } else {
            [self.timeWaiting invalidate];
            self.timeWaiting = nil;
            //[[PubNubService sharedInstance] sendTypingStateOnChannel:[self.buddy getPrivateChannel] isTyping:NO];
        }
    }
}

-(void)handleTimer:(NSTimer *)timer
{
    //Update Values in Label here
    NSDictionary *dict = [timer userInfo];
    BOOL one = [[self.inputToolbar.contentView.textView text] isEqualToString:[dict valueForKey:@"text"]];
    BOOL two = [self.inputToolbar.contentView.textView hasText];
    if (one || two) {
        //[[PubNubService sharedInstance] sendTypingStateOnChannel:[self.buddy getPrivateChannel] isTyping:NO];
    }
    
    [self.timeWaiting invalidate];
    self.timeWaiting = nil;
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
    
    if (isLastMessage) {
        // Save message to display
        [self.editingDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            [message saveWithTransaction:transaction];
            self.buddy.lastMessageDate = message.date;
            [self.buddy saveWithTransaction:transaction];
        }];
    } else {
        // Update message date to show as newer message sent
        message.date = [NSDate date];
        [self.editingDatabaseConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            [message saveWithTransaction:transaction];
            self.buddy.lastMessageDate = message.date;
            [self.buddy saveWithTransaction:transaction];
        }];
    }
    
    if (message.getStatus == statusUploading || message.getStatus == statusParseError)
    {
        NSMutableDictionary *messageNSD = [NSMutableDictionary dictionaryWithDictionary:
                                           @{
                                             @"user" : self.buddy.uniqueId,
                                             @"business" : [SettingsKeys getBusinessId],
                                             @"messageType" : [NSNumber numberWithInteger:yapMessage.messageType]
                                             }];
        
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
                DDLogError(@"Message sent error: %@", error.localizedDescription);
                message.delivered = statusParseError;
                message.error = error.localizedDescription;
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
    [self dismissViewControllerAnimated:YES completion:nil];
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
                    self.subTitle.text = @"";
                    if ([SettingsKeys getMessageSoundIncoming:YES]) {
                        [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                    }
                } else {
                    [self finishSendingMessage];
                    if ([SettingsKeys getMessageSoundIncoming:NO]) {
                        [JSQSystemSoundPlayer jsq_playMessageSentSound];
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
                                           MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:mediaItem.fileURL];
                                           [view dismissViewControllerAnimated:YES completion:nil];
                                           [self presentMoviePlayerViewControllerAnimated:moviePlayer];
                                           [moviePlayer.moviePlayer play];
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
                             actionWithTitle:NSLocalizedString(@"conversation_unsent_alert_action_cancel", nil)
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
