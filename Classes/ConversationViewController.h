//
//  ConversationViewController.h
//  Conversa
//
//  Created by Edgar Gomez on 11/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import UIKit;
@class Business, YapContact, YapMessage;
#import "CustomAblyRealtime.h"
#import <Parse/Parse.h>
#import <OHQBImagePicker/QBImagePicker.h>
#import <JSQMessagesViewController/JSQMessages.h>

@interface ConversationViewController : JSQMessagesViewController
<JSQMessagesComposerTextViewPasteDelegate, UIImagePickerControllerDelegate, QBImagePickerControllerDelegate, ConversationListener>

@property(nonatomic, assign) BOOL checkIfAlreadyAdded;
@property(nonatomic, strong) YapContact *buddy;

- (void)initWithBuddy:(YapContact *)buddy;
- (void)initWithBusiness:(Business *)business withAvatarUrl:(NSString*)url;
- (void)sendWithYapMessage:(YapMessage *)yapMessage isLastMessage:(BOOL)value withPFFile:(PFFile *)file;

@end
