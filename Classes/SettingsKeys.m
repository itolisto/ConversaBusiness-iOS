//
//  SettingsKeys.m
//  Conversa
//
//  Created by Edgar Gomez on 2/27/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "SettingsKeys.h"

@implementation SettingsKeys

// General
NSString *tutorialAlreadyShown = @"tutorialAlreadyShown";
NSString *notificationsCheck   = @"notificationsCheck";

// Account settings
NSString *sendToConversaSwitch = @"sendToConversaSwitch";
NSString *sendReadSwitch       = @"sendReadSwitch";

// Notifications settings
NSString *inAppSoundSwitch    = @"inAppSoundSwitch";
NSString *inAppPreviewSwitch  = @"inAppPreviewSwitch";
NSString *soundSwitch         = @"soundSwitch";
NSString *previewSwitch       = @"previewSwitch";

// Message settings
NSString *qualityImageSetting = @"qualityImageSetting";
NSString *sendSoundSwitch     = @"sendSoundSwitch";
NSString *receiveSoundSwitch  = @"receiveSoundSwitch";

#pragma mark - Defaults -
+ (NSUserDefaults *)getDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return defaults;
}

#pragma mark - General settings -

+ (void)setTutorialShownSetting:(BOOL)state {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setBool:state forKey:tutorialAlreadyShown];
    [defaults synchronize];
}

+ (BOOL)getTutorialShownSetting {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults boolForKey:tutorialAlreadyShown];
}

+ (void)setNotificationsCheck:(BOOL)state {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setBool:state forKey:notificationsCheck];
    [defaults synchronize];
}

+ (BOOL)getNotificationsCheck {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults boolForKey:notificationsCheck];
}

#pragma mark - Account settings -
+ (void)setSendToConversaSetting:(BOOL)state {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setBool:state forKey:sendToConversaSwitch];
    [defaults synchronize];
}

+ (BOOL)getSendToConversaSetting {
    NSUserDefaults *defaults = [self getDefaults];
    if([defaults boolForKey:sendToConversaSwitch]) {
        return YES;
    }
    
    return NO;
}

+ (void)setSendReadSetting:(BOOL)state {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setBool:state forKey:sendReadSwitch];
    [defaults synchronize];
}

+ (BOOL)getSendReadSetting {
    NSUserDefaults *defaults = [self getDefaults];
    if([defaults boolForKey:sendReadSwitch]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Notifications settings -
+ (void)setNotificationSound:(BOOL) state inApp:(BOOL) inApp {
    NSUserDefaults *defaults = [self getDefaults];
    
    if(inApp) {
        [defaults setBool:state forKey:inAppSoundSwitch];
    } else {
        [defaults setBool:state forKey:soundSwitch];
    }
    
    [defaults synchronize];
}

+ (void)setNotificationPreview:(BOOL) state inApp:(BOOL)inApp {
    NSUserDefaults *defaults = [self getDefaults];
    
    if(inApp) {
        [defaults setBool:state forKey:inAppPreviewSwitch];
    } else {
        [defaults setBool:state forKey:previewSwitch];
    }
    
    [defaults synchronize];
}

+ (BOOL)getNotificationSoundInApp:(BOOL)inApp {
    NSUserDefaults *defaults = [self getDefaults];
    
    if(inApp) {
        if([defaults boolForKey:inAppSoundSwitch]) {
            return YES;
        }
        
        return NO;
    }
    
    if([defaults boolForKey:soundSwitch]) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)getNotificationPreviewInApp:(BOOL)inApp {
    NSUserDefaults *defaults = [self getDefaults];
    
    if(inApp) {
        if([defaults boolForKey:inAppPreviewSwitch]) {
            return YES;
        }
        
        return NO;
    }
    
    if([defaults boolForKey:previewSwitch]) {
        return YES;
    }
    
    return NO;
}


#pragma mark - Message settings -
+ (void)setMessageImageQuality:(ConversaImageQuality)quality {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setInteger:quality forKey:qualityImageSetting];
    [defaults synchronize];
}

+ (ConversaImageQuality)getMessageImageQuality {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults integerForKey:qualityImageSetting];
}

+ (void)setMessageSoundIncoming:(BOOL)incoming value:(BOOL)state {
    NSUserDefaults *defaults = [self getDefaults];
    
    if(incoming) {
        [defaults setBool:state forKey:receiveSoundSwitch];
    } else {
        [defaults setBool:state forKey:sendSoundSwitch];
    }
    
    [defaults synchronize];
}

+ (BOOL)getMessageSoundIncoming:(BOOL)incoming {
    NSUserDefaults *defaults = [self getDefaults];
    
    if(incoming) {
        if([defaults boolForKey:receiveSoundSwitch]) {
            return YES;
        }
        
        return NO;
    } else {
        if([defaults boolForKey:sendSoundSwitch]) {
            return YES;
        }
        
        return NO;
    }
}

@end