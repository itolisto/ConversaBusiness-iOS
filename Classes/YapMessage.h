//
//  OTRMessage.h
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

@class YapContact, YapDatabaseReadTransaction, YapMessage;
#import "YapDatabaseObject.h"
#import <CoreLocation/CoreLocation.h>
#import <YapDatabase/YapDatabaseRelationshipNode.h>

// PubNubMessage
typedef NS_ENUM(NSInteger, MessageStatus) {
    statusParseError = 1,
    statusAllDelivered = 2,
    statusServerDelivered = 3,
    statusReceived = 4,
    statusDownloading = 5,
    statusUploading = 6
};

extern const struct YapMessageAttributes {
    __unsafe_unretained NSString *text;
} YapMessageAttributes;

extern const struct YapMessageEdges {
    __unsafe_unretained NSString *buddy;
} YapMessageEdges;

typedef void (^YapMessageCompletionResult)(YapMessage* message);

@interface YapMessage : YapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong) NSDate   *date;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString  *error;
@property (nonatomic, getter = getStatus) MessageStatus delivered;
@property (nonatomic, getter = isRead) BOOL read;
@property (nonatomic, getter = isView) BOOL view;
@property (nonatomic, getter = isIncoming) BOOL incoming;
@property (nonatomic, strong) NSString   *remoteUrl;     // For audio, video & image
@property (nonatomic, strong) NSString   *filename;     // For audio, video & image
@property (nonatomic, strong) CLLocation *location;     // For location
@property (nonatomic, assign) NSInteger messageType;
@property (nonatomic, assign) int transferProgress;

@property (nonatomic, assign) CGFloat width;    // For Image
@property (nonatomic, assign) CGFloat height;   // For Image
@property (nonatomic, assign) NSNumber *duration; // Audio & video
@property (nonatomic, assign) CGFloat bytes; // Size in Mb

@property (nonatomic, strong) NSString *buddyUniqueId;

- (instancetype)initWithId:(NSString*)uniqueId;
- (YapContact *)buddyWithTransaction:(YapDatabaseReadTransaction *)readTransaction;

+ (void)deleteAllMessagesWithTransaction:(YapDatabaseReadWriteTransaction*)transaction;
+ (void)deleteAllMessagesForBuddyId:(NSString *)uniqueBuddyId
                        transaction:(YapDatabaseReadWriteTransaction*)transaction;
+ (void)receivedDeliveryReceiptForMessageId:(NSString *)messageId
                                transaction:(YapDatabaseReadWriteTransaction*)transaction;
+ (void)enumerateMessagesWithMessageId:(NSString *)messageId
                           transaction:(YapDatabaseReadTransaction *)transaction usingBlock:(void (^)(YapMessage *message,BOOL *stop))block;
+ (void)showLocalNotificationForMessage:(YapMessage *)message;
+ (void)saveMessageWithDictionary:(NSDictionary*)messageDic block:(YapMessageCompletionResult)block;

- (void)touchMessage;
- (void)touchMessageWithTransaction:(YapDatabaseReadWriteTransaction *)transaction;

@end
