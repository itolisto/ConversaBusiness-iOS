//
//  OTRNotificationPermissions.m
//  ChatSecure
//
//  Created by David Chiles on 10/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "NotificationPermissions.h"

#import "AppDelegate.h"
#include <CoreLocation/CoreLocation.h>

@implementation NotificationPermissions

+ (BOOL)checkPermissions:(UIViewController *)controller
{
    if([CLLocationManager locationServicesEnabled]) {
        if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            UIAlertController * view =  [UIAlertController
                                         alertControllerWithTitle:@"App Permission Denied"
                                         message:@"To re-enable, please go to Settings and turn on Location Service for this app."
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Ok"
                                                         style:UIAlertActionStyleCancel
                                                       handler:^(UIAlertAction * action)
                                 {
                                     [view dismissViewControllerAnimated:YES completion:nil];
                                 }];
            
            [view addAction:ok];
            [controller presentViewController:view animated:YES completion:nil];
            
            return NO;
        }
        
        return YES;
    } else {
        return NO;
    }
}

+ (void)canSendNotifications
{
    // Override point for customization after application launch.
    // We want to check Notification Settings on launch.
    // First we must determine your iOS type:
    // Note this will only work for iOS 8 and up, if you require iOS 7 notifications then
    // contact support@pubnub.com with your request
    float systemVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (systemVersion >= 10) {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            switch (settings.authorizationStatus) {
                    // This means we have not yet asked for notification permissions
                case UNAuthorizationStatusNotDetermined:
                {
                    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
                        // You might want to remove this, or handle errors differently in production
                        //NSAssert(error == nil, @"There should be no error");
                        if (granted) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[UIApplication sharedApplication] registerForRemoteNotifications];
                            });
                        }
                    }];
                }
                    break;
                    // We are already authorized, so no need to ask
                case UNAuthorizationStatusAuthorized:
                {
                    // Just try and register for remote notifications
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] registerForRemoteNotifications];
                    });
                }
                    break;
                    // We are denied User Notifications
                case UNAuthorizationStatusDenied:
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // Possibly display something to the user
                        UIAlertController *useNotificationsController = [UIAlertController alertControllerWithTitle:@"Turn on notifications" message:@"This app needs notifications turned on for the best user experience" preferredStyle:UIAlertControllerStyleAlert];
                        UIAlertAction *goToSettingsAction = [UIAlertAction actionWithTitle:@"Go to settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {

                        }];
                        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
                        [useNotificationsController addAction:goToSettingsAction];
                        [useNotificationsController addAction:cancelAction];
                        [((AppDelegate*)[UIApplication sharedApplication].delegate).window.rootViewController presentViewController:useNotificationsController animated:true completion:nil];
                        NSLog(@"We cannot use notifications because the user has denied permissions");
                    });
                }
                    break;
            }
        }];
    } else if ((systemVersion < 10) || (systemVersion >= 8)) {
        UIUserNotificationType types = (UIUserNotificationTypeBadge | UIUserNotificationTypeSound |
                                        UIUserNotificationTypeAlert);
        UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:nil];

        [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
    } else {
        NSLog(@"We cannot handle iOS 7 or lower in this example. Contact support@pubnub.com");
    }
}

@end
