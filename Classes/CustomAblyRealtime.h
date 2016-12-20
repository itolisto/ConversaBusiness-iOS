//
//  CustomSinchService.h
//  Conversa
//
//  Created by Edgar Gomez on 7/18/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import Foundation;
@import Ably;

@class YapContact, YapMessage;

@protocol ConversationListener <NSObject>
@required
- (void) messageReceived:(YapMessage*)message from:(YapContact*)from text:(NSString*)text;
@optional
- (void) fromUser:(NSString*)objectId userIsTyping:(BOOL)isTyping;
// The only status is shown is 'online' and only visible if user enters chat with this user
- (void) fromUser:(NSString*)objectId didGoOnline:(BOOL)status; // YES online NO maybe online/maybe not
@end

typedef void (^SinchServicePublishCompletionBlock)(NSNumber *timeToken);//PNErrorData *err,

@interface CustomAblyRealtime : NSObject

// Stores reference on PubNub client to make sure what it won't be released.
@property(strong, nonatomic) ARTRealtime *ably;
@property(nonatomic, weak) id<ConversationListener> delegate;

+ (CustomAblyRealtime *)sharedInstance;
- (void)initAbly;
- (void)logout;

- (void)sendTypingStateOnChannel:(NSString*)channel isTyping:(BOOL)value;

- (void)subscribeToChannels:(NSArray*)channels;
- (void)unsubscribeToChannels:(NSArray*)channels;
- (void)unsubscribeFromAllChannels;

@end
