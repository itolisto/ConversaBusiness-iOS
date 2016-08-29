//
//  OneSignalService.h
//  Conversa
//
//  Created by Edgar Gomez on 7/18/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import Foundation;
#import <OneSignal/OneSignal.h>

@interface OneSignalService : NSObject

+ (OneSignalService *)sharedInstance;
- (void)launchWithOptions:(NSDictionary *)launchOptions;
- (void)registerForPushNotifications;
- (void)startTags;

- (void)subscribeToAllChannels:(BOOL)presence;
- (void)subscribeToChannels:(NSArray*)channels;
- (void)unsubscribeToChannels:(NSArray*)channels;
- (void)unsubscribeFromAllChannels;

@end