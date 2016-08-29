//
//  SettingsKeys.h
//  Conversa
//
//  Created by Edgar Gomez on 2/27/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import Foundation;
#import "Constants.h"

// General
extern NSString *tutorialAlreadyShown;
extern NSString *notificationsCheck;
// Account settings
extern NSString *sendToConversaSwitch;
// Notifications settings
extern NSString *inAppSoundSwitch;
extern NSString *inAppPreviewSwitch;
extern NSString *soundSwitch;
extern NSString *previewSwitch;

@interface SettingsKeys : NSObject

// General
+ (void)setTutorialShownSetting:(BOOL)state;
+ (BOOL)getTutorialShownSetting;
+ (void)setNotificationsCheck:(BOOL)state;
+ (BOOL)getNotificationsCheck;

// Account settings
+ (void)setSendToConversaSetting:(BOOL)state;
+ (BOOL)getSendToConversaSetting;
+ (void)setSendReadSetting:(BOOL)state;
+ (BOOL)getSendReadSetting;

// Notifications settings
+ (void)setNotificationSound:(BOOL)state inApp:(BOOL)inApp;
+ (void)setNotificationPreview:(BOOL)state inApp:(BOOL)inApp;
+ (BOOL)getNotificationSoundInApp:(BOOL)inApp;
+ (BOOL)getNotificationPreviewInApp:(BOOL)inApp;

// Messages settings
+ (void)setMessageImageQuality:(ConversaImageQuality)quality;
+ (ConversaImageQuality)getMessageImageQuality;

+ (void)setMessageSoundIncoming:(BOOL)incoming value:(BOOL)state;
+ (BOOL)getMessageSoundIncoming:(BOOL)incoming;

@end
