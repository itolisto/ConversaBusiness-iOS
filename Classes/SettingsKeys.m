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
NSString *customerObjectId  = @"customerObjectId";
NSString *customerDisplayName  = @"customerDisplayName";
NSString *customerPaidPlan  = @"customerPaidPlan";
NSString *customerCountry  = @"customerCountry";
NSString *customerConversaId  = @"customerConversaId";
NSString *customerAbout  = @"customerAbout";
NSString *customerVerified  = @"customerVerified";
NSString *customerRedirect  = @"customerRedirect";
NSString *customerAvatarUrl  = @"customerAvatarUrl";

NSString *readReceiptsSwitch  = @"readReceiptsSwitch";

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
+ (void)setBusinessId:(NSString*)objectId {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:objectId forKey:customerObjectId];
    [defaults synchronize];
}

+ (NSString*)getBusinessId {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:customerObjectId];
}

+ (void)setDisplayName:(NSString*)displayName {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:displayName forKey:customerDisplayName];
    [defaults synchronize];
}

+ (NSString*)getDisplayName {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:customerDisplayName];
}

+ (void)setPaidPlan:(NSString*)paidplan {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:paidplan forKey:customerPaidPlan];
    [defaults synchronize];
}

+ (NSString*)getPaidPlan {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:customerPaidPlan];
}

+ (void)setCountry:(NSString*)country {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:country forKey:customerCountry];
    [defaults synchronize];
}

+ (NSString*)getCountry {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:customerCountry];
}

+ (void)setConversaId:(NSString*)conversaid {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:conversaid forKey:customerConversaId];
    [defaults synchronize];
}

+ (NSString*)getConversaId {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:customerConversaId];
}

+ (void)setAbout:(NSString*)about {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:about forKey:customerAbout];
    [defaults synchronize];
}

+ (NSString*)getAbout {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:customerAbout];
}

+ (void)setVerified:(BOOL)verifed {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setBool:verifed forKey:customerVerified];
    [defaults synchronize];
}

+ (BOOL)getVerified {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults boolForKey:customerVerified];
}

+ (void)setRedirect:(BOOL)redirect {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setBool:redirect forKey:customerRedirect];
    [defaults synchronize];
}

+ (BOOL)getRedirect {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults boolForKey:customerRedirect];
}

+ (void)setAvatarUrl:(NSString*)url {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:url forKey:customerAvatarUrl];
    [defaults synchronize];
}

+ (NSString*)getAvatarUrl {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:customerAvatarUrl];
}

+ (void)setAccountReadSetting:(BOOL) state {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setBool:state forKey:readReceiptsSwitch];
    [defaults synchronize];
}

+ (BOOL)getAccountReadSetting {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults boolForKey:readReceiptsSwitch];
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
        return [defaults boolForKey:inAppSoundSwitch];
    }

    return [defaults boolForKey:soundSwitch];
}

+ (BOOL)getNotificationPreviewInApp:(BOOL)inApp {
    NSUserDefaults *defaults = [self getDefaults];

    if(inApp) {
        return [defaults boolForKey:inAppPreviewSwitch];
    }

    return [defaults boolForKey:previewSwitch];
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
        return [defaults boolForKey:receiveSoundSwitch];
    } else {
        return [defaults boolForKey:sendSoundSwitch];
    }
}

@end
