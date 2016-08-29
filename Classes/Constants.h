//
//  Constants.h
//  Conversa
//
//  Created by Edgar Gomez on 9/28/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import Foundation;

// Customer class
extern NSString *const kClassCustomer;
extern NSString *const kCustomerUserInfoKey;

// Business class
extern NSString *const kClassBusiness;
extern NSString *const kBusinessBusinessInfoKey;
extern NSString *const kBusinessBelongsToCategoryKey;
extern NSString *const kBusinessOrderByPosition;

// Category class
extern NSString *const kClassCategory;

// Contact class
extern NSString *const kClassContact;
extern NSString *const kContactFromUserKey;
extern NSString *const kContactToBusinessKey;
extern NSString *const kContactActiveChatKey;

// Favorite class
extern NSString *const kClassFavorite;
extern NSString *const kFavoriteFromUserKey;
extern NSString *const kFavoriteToBusinessKey;
extern NSString *const kFavoriteIsFavoriteKey;

// Message class
extern NSString *const kClassMessage;
extern NSString *const kMessageFromUserKey;
extern NSString *const kMessageToUserKey;
extern NSString *const kMessageFileKey;
extern NSString *const kMessageThumbKey;
extern NSString *const kMessageWidthKey;
extern NSString *const kMessageHeightKey;
extern NSString *const kMessageDurationKey;
extern NSString *const kMessageLocationKey;
extern NSString *const kMessageTextKey;

// Image Quality
typedef NS_ENUM(NSInteger, ConversaImageQuality) {
    ConversaImageQualityHigh   = 1,
    ConversaImageQualityMedium = 2,
    ConversaImageQualityLow    = 3
};

// PubNubMessage
typedef NS_ENUM(NSInteger, PubNubMessageType){
    kMessageTypeText    = 1,
    kMessageTypeAudio   = 2,
    kMessageTypeVideo   = 3,
    kMessageTypeImage   = 4,
    kMessageTypeLocation  = 5
};
extern NSString *const kPubNubMessageTextKey;
extern NSString *const kPubNubMessageFromKey;
extern NSString *const kPubNubMessageFromRedirectKey;
extern NSString *const kPubNubMessageSelfKey;
extern NSString *const kPubNubMessageTypeKey;

// Messages media location
extern NSString *const kMessageMediaImageLocation;
extern NSString *const kMessageMediaVideoLocation;
extern NSString *const kMessageMediaAudioLocation;
extern NSString *const kMessageMediaThumbLocation;

// User class
extern NSString *const kUserAvatarKey;
extern NSString *const kUserUsernameKey;
extern NSString *const kUserEmailKey;
extern NSString *const kUserPasswordKey;
extern NSString *const kUserTypeKey;

// General
extern NSString *const kObjectRowObjectIdKey;
extern NSString *const kObjectRowCreatedAtKey;
extern NSString *const kOrderByCreatedAt;

// Other
extern NSString *const kAccountAvatarName;
extern NSString *const kNSDictionaryCustomer;
extern NSString *const kNSDictionaryChangeValue;
extern NSString *const kSettingKeyLanguage;
extern NSString *const kAppVersionKey;
extern NSString *const kYapDatabaseServiceName;
extern NSString *const kYapDatabasePassphraseAccountName;
extern NSString *const kYapDatabaseName;
extern NSString *const kMuteUserNotificationName;

// YapDatabase
#define		YapDatabaseModifiedNotificationUpdate   @"update"

// Messages status & info
#define		STATUS_LOADING						1
#define		STATUS_FAILED						2
#define		STATUS_SUCCEED						3
#define     MESSAGE_FROM_SENDERID               [Account currentUser].objectId
#define     MESSAGE_FROM_SENDERDISPLAYNAME      [Account currentUser].username

// Messages dictionary keys
#define     MESSAGE_TEXT_KEY      @"text"
#define     MESSAGE_LATI_KEY      @"latitude"
#define     MESSAGE_LONG_KEY      @"longitude"
#define     MESSAGE_FILENAME_KEY  @"filename"
#define     MESSAGE_SIZE_KEY      @"size"

#define     BLOCK_NOTIFICATION_NAME             @"BlockNotificationName"
#define     SEARCH_NOTIFICATION_NAME            @"SearchNotificationName"
#define     SEARCH_NOTIFICATION_DIC_KEY         @"SearchBarText"
#define     UPDATE_CELL_NOTIFICATION_NAME       @"UpdateCellNotificationName"
#define     UPDATE_CHATS_NOTIFICATION_NAME      @"UpdateChatsNotificationName"
#define     UPDATE_CELL_DIC_KEY                 @"UpdateCellText"

#define		IMAGE_LIMIT         1 //Items
#define		VIDEO_LENGTH        15 //Seconds