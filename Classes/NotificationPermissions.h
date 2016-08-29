//
//  OTRNotificationPermissions.h
//  ChatSecure
//
//  Created by David Chiles on 10/1/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@import UIKit;

@interface NotificationPermissions : NSObject

+ (BOOL)checkPermissions:(UIViewController *)controller;
+ (bool)canSendNotifications;

@end