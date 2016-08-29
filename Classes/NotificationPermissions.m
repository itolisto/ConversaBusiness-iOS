//
//  OTRNotificationPermissions.m
//  ChatSecure
//
//  Created by David Chiles on 10/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "NotificationPermissions.h"
#include <CoreLocation/CoreLocation.h>

static const UIUserNotificationType USER_NOTIFICATION_TYPES_REQUIRED = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;

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

+ (bool)canSendNotifications
{
    UIUserNotificationSettings* notificationSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    return notificationSettings.types == USER_NOTIFICATION_TYPES_REQUIRED;
}

@end