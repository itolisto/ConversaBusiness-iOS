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
extern NSString *customerObjectId;
extern NSString *customerDisplayName;
extern NSString *customerPaidPlan;
extern NSString *customerCountry;
extern NSString *customerConversaId;
extern NSString *customerAbout;
extern NSString *customerVerified;
extern NSString *customerRedirect;
extern NSString *customerAvatarUrl;
// Notifications settings
extern NSString *inAppSoundSwitch;
extern NSString *inAppPreviewSwitch;
extern NSString *soundSwitch;
extern NSString *previewSwitch;

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
