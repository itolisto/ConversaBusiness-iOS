//
//  OneSignalService.m
//  Conversa
//
//  Created by Edgar Gomez on 7/18/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "OneSignalService.h"

#import "Log.h"
#import "SettingsKeys.h"
#import "CustomAblyRealtime.h"

@interface OneSignalService ()

@property(nonatomic, assign)BOOL registerCalled;

@end

@implementation OneSignalService

+ (OneSignalService *)sharedInstance {
    __strong static OneSignalService *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[OneSignalService alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Connection Methods -

- (instancetype)init
{
    if (self = [super init]) {
        self.registerCalled = NO;
    }

    return self;
}

- (void)launchWithOptions:(NSDictionary *)launchOptions {
    [OneSignal initWithLaunchOptions:launchOptions
                               appId:@"a652c1d3-e681-4538-9486-7b855d90e6aa"
          handleNotificationReceived:^(OSNotification *notification)
     {
         // Function to be called when a notification is received.
         OSNotificationPayload* payload = notification.payload;

         if (payload.additionalData) {
             NSDictionary* additionalData = payload.additionalData;
             [self performSelector:@selector(processMessage:) withObject:additionalData afterDelay:0.9];
         }
     }
            handleNotificationAction:^(OSNotificationOpenedResult *result)
     {
         // Function to be called when a user reacts to a notification received.
         DDLogWarn(@"handleNotificationAction (:");
     }
                            settings:@{kOSSettingsKeyInAppAlerts: @NO, kOSSettingsKeyAutoPrompt: @NO}];
}

- (void)processMessage:(NSDictionary*)additionalData {
    [[CustomAblyRealtime sharedInstance] onMessage:additionalData];
}

- (void)registerForPushNotifications
{
    if (self.registerCalled) {
        DDLogWarn(@"Method registerForPushNotifications can only be called once");
        return;
    }

    self.registerCalled = YES;
    [OneSignal registerForPushNotifications];
}

- (void)startTags {
    [OneSignal sendTags:@{@"usertype" : @(2),
                          @"bpbc" : [SettingsKeys getBusinessId],
                          @"bpvt" : [SettingsKeys getBusinessId]}
              onSuccess:^(NSDictionary *result)
     {
         NSLog(@"ONE SIGNAL SUCCESS: %@", result);
     } onFailure:^(NSError *error) {
         NSLog(@"ONE SIGNAL ERROR: %@", error);
     }];
}

#pragma mark - Class Methods -

- (void)unsubscribeFromAllChannels {
    
}

@end
