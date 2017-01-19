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
NSString *businessObjectId  = @"businessObjectId";
NSString *businessDisplayName  = @"businessDisplayName";
NSString *businessPaidPlan  = @"businessPaidPlan";
NSString *businessCountry  = @"businessCountry";
NSString *businessConversaId  = @"businessConversaId";
NSString *businessAbout  = @"businessAbout";
NSString *businessVerified  = @"businessVerified";
NSString *businessRedirect  = @"businessRedirect";
NSString *businessAvatarUrl  = @"businessAvatarUrl";
NSString *businessStatus  = @"businessStatus";
NSString *businessCategories  = @"businessCategories";

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
    [defaults setObject:objectId forKey:businessObjectId];
    [defaults synchronize];
}

+ (NSString*)getBusinessId {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:businessObjectId];
}

+ (void)setDisplayName:(NSString*)displayName {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:displayName forKey:businessDisplayName];
    [defaults synchronize];
}

+ (NSString*)getDisplayName {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:businessDisplayName];
}

+ (void)setPaidPlan:(NSString*)paidplan {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:paidplan forKey:businessPaidPlan];
    [defaults synchronize];
}

+ (NSString*)getPaidPlan {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:businessPaidPlan];
}

+ (void)setCountry:(NSString*)country {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:country forKey:businessCountry];
    [defaults synchronize];
}

+ (NSString*)getCountry {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:businessCountry];
}

+ (void)setConversaId:(NSString*)conversaid {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:conversaid forKey:businessConversaId];
    [defaults synchronize];
}

+ (NSString*)getConversaId {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:businessConversaId];
}

+ (void)setAbout:(NSString*)about {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:about forKey:businessAbout];
    [defaults synchronize];
}

+ (NSString*)getAbout {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:businessAbout];
}

+ (void)setVerified:(BOOL)verifed {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setBool:verifed forKey:businessVerified];
    [defaults synchronize];
}

+ (BOOL)getVerified {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults boolForKey:businessVerified];
}

+ (void)setRedirect:(BOOL)redirect {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setBool:redirect forKey:businessRedirect];
    [defaults synchronize];
}

+ (BOOL)getRedirect {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults boolForKey:businessRedirect];
}

+ (void)setAvatarUrl:(NSString*)url {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setObject:url forKey:businessAvatarUrl];
    [defaults synchronize];
}

+ (NSString*)getAvatarUrl {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults stringForKey:businessAvatarUrl];
}

+ (void)setAccountReadSetting:(BOOL)state {
    NSUserDefaults *defaults = [self getDefaults];
    [defaults setBool:state forKey:readReceiptsSwitch];
    [defaults synchronize];
}

+ (BOOL)getAccountReadSetting {
    NSUserDefaults *defaults = [self getDefaults];
    return [defaults boolForKey:readReceiptsSwitch];
}

+ (void)setStatus:(NSInteger)status {
    if (status < 0 || status > 2) {
        if (status != -1) {
            return;
        }
    }

    NSUserDefaults *defaults = [self getDefaults];
    [defaults setInteger:status forKey:businessStatus];
    [defaults synchronize];
}

+ (BusinessStatus)getStatus {
    NSUserDefaults *defaults = [self getDefaults];
    switch ([defaults integerForKey:businessStatus]) {
        case 0:
            return Online;
        case 1:
            return Away;
        case 2:
            return Offline;
        default:
            return Conversa;
    }
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
    switch (quality) {
        case ConversaImageQualityHigh:
            [defaults setInteger:1 forKey:qualityImageSetting]; break;
        case ConversaImageQualityMedium:
            [defaults setInteger:2 forKey:qualityImageSetting]; break;
        default:
            [defaults setInteger:3 forKey:qualityImageSetting]; break;
    }
    [defaults synchronize];
}

+ (ConversaImageQuality)getMessageImageQuality {
    NSUserDefaults *defaults = [self getDefaults];
    switch ([defaults integerForKey:qualityImageSetting]) {
        case 1:
            return ConversaImageQualityHigh;
        case 2:
            return ConversaImageQualityMedium;
        default:
            return ConversaImageQualityLow;
    }
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
