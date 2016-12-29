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
extern NSString *firstCategoriesLoad;
extern NSString *notificationsCheck;
// Account settings
extern NSString *readReceiptsSwitch;
extern NSString *businessObjectId;
extern NSString *businessDisplayName;
extern NSString *businessPaidPlan;
extern NSString *businessCountry;
extern NSString *businessConversaId;
extern NSString *businessAbout;
extern NSString *businessVerified;
extern NSString *businessRedirect;
extern NSString *businessAvatarUrl;
extern NSString *businessStatus;
extern NSString *businessCategories;
// Notifications settings
extern NSString *inAppSoundSwitch;
extern NSString *inAppPreviewSwitch;
extern NSString *soundSwitch;
extern NSString *previewSwitch;

typedef NS_ENUM(NSUInteger, BusinessStatus) {
    Online = 0,
    Away = 1,
    Offline = 2,
    Conversa = -1
};

@interface SettingsKeys : NSObject

// General
+ (void)setTutorialShownSetting:(BOOL)state;
+ (void)setNotificationsCheck:(BOOL)state;
+ (BOOL)getTutorialShownSetting;
+ (BOOL)getNotificationsCheck;

// Account settings
+ (void)setBusinessId:(NSString*)objectId;
+ (NSString*)getBusinessId;
+ (void)setDisplayName:(NSString*)displayName;
+ (NSString*)getDisplayName;
+ (void)setPaidPlan:(NSString*)paidplan;
+ (NSString*)getPaidPlan;
+ (void)setCountry:(NSString*)country;
+ (NSString*)getCountry;
+ (void)setConversaId:(NSString*)conversaid;
+ (NSString*)getConversaId;
+ (void)setAbout:(NSString*)about;
+ (NSString*)getAbout;
+ (void)setVerified:(BOOL)verifed;
+ (BOOL)getVerified;
+ (void)setRedirect:(BOOL)redirect;
+ (BOOL)getRedirect;
+ (void)setAvatarUrl:(NSString*)url;
+ (NSString*)getAvatarUrl;
+ (void)setStatus:(NSInteger)status;
+ (BusinessStatus)getStatus;

+ (void)setAccountReadSetting:(BOOL)state;
+ (BOOL)getAccountReadSetting;

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

// General
//+ (void)setTutorialShownSetting:(BOOL)state;
//+ (BOOL)getTutorialShownSetting;
//+ (void)setNotificationsCheck:(BOOL)state;
//+ (BOOL)getNotificationsCheck;
