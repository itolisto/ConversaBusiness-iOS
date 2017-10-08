//
//  CustomAblyRealtime.h
//  Conversa
//
//  Created by Edgar Gomez on 7/18/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import Foundation;
@import Ably;

@class YapContact, YapMessage;

@protocol ConversationListener <NSObject>
@optional
    - (void)messageReceived:(YapMessage*)message from:(YapContact*)from;
    - (void)fromUser:(NSString*)objectId userIsTyping:(BOOL)isTyping;
    // The only status is shown is 'online' and only visible if user enters chat with this user
    - (void)fromUser:(NSString*)objectId didGoOnline:(BOOL)status; // YES online NO maybe online/maybe not
@end

@interface CustomAblyRealtime : NSObject <ARTPushRegistererDelegate>

// Stores reference on PubNub client to make sure what it won't be released.
@property(strong, nonatomic) ARTRealtime *ably;
@property(strong, nonatomic) NSString *clientId;
@property(nonatomic, weak) id<ConversationListener> delegate;

+ (CustomAblyRealtime *)sharedInstance;
- (ARTRealtime*)getAblyRealtime;
- (void)initAbly;
- (void)logout;

- (void)subscribeToChannels;
- (void)subscribeToPushNotifications:(NSData *)devicePushToken;
- (void)unsubscribeToPushNotification:(NSData *)deviceToken;

- (NSString *)getPublicConnectionId;
- (void)onMessage:(NSDictionary *)results;
- (void)sendTypingStateOnChannel:(NSString*)channel isTyping:(BOOL)value;

@end
