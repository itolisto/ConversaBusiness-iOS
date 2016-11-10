//
//  Constants.m
//  Conversa
//
//  Created by Edgar Gomez on 9/28/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "Constants.h"

// Customer class
NSString *const kClassCustomer       = @"Customer";
NSString *const kCustomerUserInfoKey = @"userInfo";

// Business class
NSString *const kClassBusiness                = @"Business";
NSString *const kBusinessBusinessInfoKey      = @"businessInfo";
NSString *const kBusinessBelongsToCategoryKey = @"belongsToCategory";
NSString *const kBusinessOrderByPosition      = @"categoryPosition";

// Category class
NSString *const kClassCategory = @"Category";

// Contact class
NSString *const kClassContact         = @"UserContact";
NSString *const kContactFromUserKey   = @"fromUser";
NSString *const kContactToBusinessKey = @"toBusiness";
NSString *const kContactActiveChatKey = @"activeChat";

// Favorite class
NSString *const kClassFavorite         = @"UserFavorite";
NSString *const kFavoriteFromUserKey   = @"fromUser";
NSString *const kFavoriteToBusinessKey = @"toBusiness";;
NSString *const kFavoriteIsFavoriteKey = @"isCurrentlyFavorite";

// Message class
NSString *const kClassMessage       = @"Message";
NSString *const kMessageFromUserKey = @"fromUser";
NSString *const kMessageToUserKey   = @"toUser";
NSString *const kMessageFileKey     = @"file";
NSString *const kMessageThumbKey    = @"thumbnail";
NSString *const kMessageWidthKey    = @"width";
NSString *const kMessageHeightKey   = @"height";
NSString *const kMessageDurationKey = @"duration";
NSString *const kMessageLocationKey = @"location";
NSString *const kMessageTextKey     = @"text";

// PubNubMessage class
NSString *const kPubNubMessageTextKey = @"message";
NSString *const kPubNubMessageFromKey = @"from";
NSString *const kPubNubMessageFromRedirectKey = @"fromRedirect";
NSString *const kPubNubMessageSelfKey = @"kPubNubMessageSelfKey";
NSString *const kPubNubMessageTypeKey = @"type";

// Messages media location
NSString *const kMessageMediaImageLocation = @"/image";
NSString *const kMessageMediaVideoLocation = @"/video";
NSString *const kMessageMediaAudioLocation = @"/audio";
NSString *const kMessageMediaThumbLocation = @"/thumb";

// User class
NSString *const kUserAvatarKey   = @"avatar";
NSString *const kUserUsernameKey = @"username";
NSString *const kUserEmailKey    = @"email";
NSString *const kUserPasswordKey = @"password";
NSString *const kUserTypeKey     = @"userType";

// General
NSString *const kObjectRowObjectIdKey  = @"objectId";
NSString *const kObjectRowCreatedAtKey = @"createdAt";
NSString *const kOrderByCreatedAt      = @"createdAt";

// Other
NSString *const kAccountAvatarName          = @"user_avatar.png";
NSString *const kNSDictionaryCustomer       = @"objectCustomer";
NSString *const kNSDictionaryChangeValue    = @"hasChangeValue";
NSString *const kSettingKeyLanguage         = @"userSelectedSetting";
NSString *const kAppVersionKey              = @"kAppVersionKey";
NSString *const kYapDatabaseServiceName     = @"ee.app.Conversa";
NSString *const kYapDatabaseName            = @"ConversaManagerYap.sqlite";
NSString *const kYapDatabasePassphraseAccountName = @"YapDatabasePassphraseAccountName";
NSString *const kMuteUserNotificationName   = @"kMuteUserNotificationName";
