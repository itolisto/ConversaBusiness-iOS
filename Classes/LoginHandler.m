//
//  LoginHandler.m
//  Conversa
//
//  Created by Edgar Gomez on 12/23/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "LoginHandler.h"

#import "Account.h"
#import "Constants.h"
#import "YapAccount.h"
#import "SettingsKeys.h"
#import "DatabaseManager.h"

@import Firebase;

@implementation LoginHandler

+ (void) proccessLoginForAccount:(FIRUser *)account fromViewController:(UIViewController*)controller {
    // Save as YapAccount
    YapAccount *newAccount = [[YapAccount alloc]initWithUniqueId:account.uid];
    [[DatabaseManager sharedInstance].newConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
    {
        [newAccount saveWithTransaction:transaction];
    }];
    // Default settings
    [SettingsKeys setAccountReadSetting:NO];
    [SettingsKeys setNotificationSound:YES inApp:YES];
    [SettingsKeys setNotificationPreview:YES inApp:YES];
    [SettingsKeys setNotificationSound:YES inApp:NO];
    [SettingsKeys setNotificationPreview:YES inApp:NO];
    [SettingsKeys setMessageImageQuality:ConversaImageQualityMedium];
    [SettingsKeys setMessageSoundIncoming:YES value:YES];
    [SettingsKeys setMessageSoundIncoming:NO value:YES];
    [SettingsKeys setTutorialShownSetting:YES];
    //[SettingsKeys setCategoriesLoad:NO];
    // Go to
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"HomeView"];
    [controller presentViewController:viewController animated:YES completion:nil];
}

@end
