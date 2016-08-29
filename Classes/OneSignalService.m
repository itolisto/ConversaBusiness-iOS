//
//  OneSignalService.m
//  Conversa
//
//  Created by Edgar Gomez on 7/18/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "OneSignalService.h"

#import "Log.h"
#import "Account.h"
#import "Message.h"
#import "Business.h"
#import "YapContact.h"
#import "YapMessage.h"
#import "DatabaseManager.h"
#import <Parse/Parse.h>

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
                               appId:@"a7c846a3-8f63-4200-8b24-15be48dcd6b2"
          handleNotificationReceived:^(OSNotification *notification)
     {
         // Function to be called when a notification is received.
         OSNotificationPayload* payload = notification.payload;


         NSString* messageTitle = @"OneSignal Example";
         NSString* fullMessage = [payload.body copy];

         if (payload.additionalData) {

             if(payload.title)
                 messageTitle = payload.title;

             NSDictionary* additionalData = payload.additionalData;

             if (additionalData[@"actionSelected"])
                 fullMessage = [fullMessage stringByAppendingString:[NSString stringWithFormat:@"\nPressed ButtonId:%@", additionalData[@"actionSelected"]]];
         }
     }
            handleNotificationAction:^(OSNotificationOpenedResult *result)
     {
         // Function to be called when a user reacts to a notification received.
     }
                            settings:@{kOSSettingsKeyInAppAlerts: @NO, kOSSettingsKeyAutoPrompt: @NO}];
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
    [OneSignal sendTags:@{@"UserType" : @(2),
                          @"bpbc" : [[Account currentUser] objectId],
                          @"bpvt" : [[Account currentUser] objectId]}
              onSuccess:^(NSDictionary *result)
     {
         NSLog(@"ONE SIGNAL SUCCESS: %@", result);
     } onFailure:^(NSError *error) {
         NSLog(@"ONE SIGNAL ERROR: %@", error);
     }];
}

#pragma mark - Process message Method -

- (void)processMessage:(NSDictionary *)additionalData {
    NSString* customKey = additionalData[@"customKey"];
    if (customKey)
        NSLog(@"customKey: %@", customKey);
}

#pragma mark - Class Methods -

- (void)subscribeToAllChannels:(BOOL)presence {

}

- (void)subscribeToChannels:(NSArray*)channels {

}

- (void)unsubscribeToChannels:(NSArray*)channels {

}

- (void)unsubscribeFromAllChannels {
    
}

@end