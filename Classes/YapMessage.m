//
//  OTRMessage.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "YapMessage.h"

#import "AppJobs.h"
#import "Constants.h"
#import "YapAccount.h"
#import "YapContact.h"
#import "DatabaseView.h"
#import "SettingsKeys.h"
#import "DatabaseManager.h"
#import "NSFileManager+Conversa.h"
#import <YapDatabase/YapDatabaseSecondaryIndex.h>
@import YapDatabase;

const struct YapMessageAttributes YapMessageAttributes = {
    .text = @"text"
};

const struct YapMessageEdges YapMessageEdges = {
    .buddy = @"buddyUniqueId"
};

@implementation YapMessage

- (instancetype)init {
    if (self = [super init]) {
        self.date = [NSDate date];
        self.text = @"";
        self.read = NO;
        self.view = NO;
        self.incoming = NO;
        self.width = 0;
        self.height = 0;
        self.duration = [NSNumber numberWithInt:0];
        self.filename = @"";
        self.remoteUrl = @"";
        self.delivered = statusUploading;
        self.messageType = kMessageTypeText;
        self.transferProgress = 0;
    }
    return self;
}

- (instancetype)initWithId:(NSString*)uniqueId {
    if (self = [super initWithUniqueId:uniqueId]) {
        self.date = [NSDate date];
        self.text = @"";
        self.read = NO;
        self.view = NO;
        self.incoming = NO;
        self.width = 0;
        self.height = 0;
        self.duration = [NSNumber numberWithInt:0];
        self.filename = @"";
        self.remoteUrl = @"";
        self.delivered = statusUploading;
        self.messageType = kMessageTypeText;
        self.transferProgress = 0;
    }
    return self;
}

- (YapContact *)buddyWithTransaction:(YapDatabaseReadTransaction *)readTransaction {
    return [YapContact fetchObjectWithUniqueID:self.buddyUniqueId transaction:readTransaction];
}

- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction {
    [self deleteMessageReceiver];
    [transaction removeObjectForKey:self.uniqueId inCollection:[[self class] collection]];
}

+ (void)saveMessageWithDictionary:(NSDictionary*)messageDic block:(YapMessageCompletionResult)block {
    NSInteger messageType = [[messageDic objectForKey:@"messageType"] integerValue];

    YapMessage* message = [[YapMessage alloc] initWithId:[messageDic objectForKey:@"messageId"]];
    message.delivered = statusReceived;
    message.buddyUniqueId = [messageDic objectForKey:@"contactId"];
    message.messageType = messageType;

    if ([[SettingsKeys getBusinessId] isEqualToString:[messageDic objectForKey:@"contactId"]]) {
        message.delivered = statusAllDelivered;
    } else {
        message.delivered = statusReceived;
    }

    if ([messageDic objectForKey:@"incoming"]) {
        message.incoming = [[messageDic objectForKey:@"incoming"] boolValue];
    } else {
        message.incoming = YES;
    }

    switch (messageType) {
        case kMessageTypeText: {
            message.text = [messageDic objectForKey:@"text"];
            break;
        }
        case kMessageTypeLocation: {
            CLLocation *location = [[CLLocation alloc]
                                    initWithLatitude:[[messageDic objectForKey:@"latitude"] doubleValue]
                                    longitude:[[messageDic objectForKey:@"longitude"] doubleValue]];
            message.location = location;
            break;
        }
        case kMessageTypeVideo:
        case kMessageTypeAudio: {
            message.delivered = statusDownloading;
            message.bytes = [[messageDic objectForKey:@"size"] floatValue];
            message.duration = [NSNumber numberWithInteger:[[messageDic objectForKey:@"duration"] integerValue]];
            message.remoteUrl = [messageDic objectForKey:@"file"];

            [AppJobs addDownloadFileJob:message.uniqueId url:message.remoteUrl messageType:messageType];
            break;
        }
        case kMessageTypeImage: {
            message.delivered = statusDownloading;
            message.bytes = [[messageDic objectForKey:@"size"] floatValue];
            message.width = [[messageDic objectForKey:@"width"] floatValue];
            message.height = [[messageDic objectForKey:@"height"] floatValue];
            message.remoteUrl = [messageDic objectForKey:@"file"];
            [AppJobs addDownloadFileJob:message.uniqueId url:message.remoteUrl messageType:messageType];
            break;
        }
    }

    //    if (self.delegate && [self.delegate respondsToSelector:@selector(messageReceived:from:)]) {
    //        if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    //        {
    //            [self.delegate messageReceived:message from:contact];
    //            return;
    //        }
    //    }

    YapDatabaseConnection *connection = [[DatabaseManager sharedInstance] newConnection];
    [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
     {
         [message saveWithTransaction:transaction];
     } completionBlock:^{
         if (block != nil) {
             block(message);
         }
     }];
}

#pragma - mark YapDatabaseRelationshipNode

- (NSArray *)yapDatabaseRelationshipEdges {
    NSArray *edges = nil;

    if (self.buddyUniqueId) {
        YapDatabaseRelationshipEdge *buddyEdge = [YapDatabaseRelationshipEdge edgeWithName:YapMessageEdges.buddy
                                                                            destinationKey:self.buddyUniqueId
                                                                                collection:[YapContact collection]
                                                                           nodeDeleteRules:
                                                  YDB_NotifyIfDestinationDeleted
                                                  |YDB_DeleteSourceIfDestinationDeleted];
        edges = @[buddyEdge];
    }

    return edges;
}

- (id)yapDatabaseRelationshipEdgeDeleted:(YapDatabaseRelationshipEdge *)edge withReason:(YDB_NotifyReason)reason {
    [self deleteMessageReceiver];
    return nil;
}

- (void)deleteMessageReceiver {
    if ([self.filename length] && (self.messageType != kMessageTypeText && self.messageType != kMessageTypeLocation)) {
        // Archivo asociado en cache
        NSError *error = nil;
        NSString *subdirectory = @"";

        switch (self.messageType) {
            case kMessageTypeAudio:{
                subdirectory = kMessageMediaAudioLocation;
                break;
            }
            case kMessageTypeImage: {
                subdirectory = kMessageMediaImageLocation;
                break;
            }
            case kMessageTypeVideo: {
                subdirectory = kMessageMediaVideoLocation;
                break;
            }
            default:
                break;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NSFileManager defaultManager] deleteDataInLibraryDirectory:self.filename
                                                          inSubDirectory:subdirectory
                                                                   error:error];
        });
    }
}

#pragma - mark Class Methods

+ (void)deleteAllMessagesWithTransaction:(YapDatabaseReadWriteTransaction*)transaction {
    [transaction removeAllObjectsInCollection:[YapMessage collection]];
}

+ (void)deleteAllMessagesForBuddyId:(NSString *)uniqueBuddyId transaction:(YapDatabaseReadWriteTransaction*)transaction {
    YapContact *buddy = [YapContact fetchObjectWithUniqueID:uniqueBuddyId transaction:transaction];
    NSDate *temp      = buddy.lastMessageDate;

    [[transaction ext:YapDatabaseRelationshipName] enumerateEdgesWithName:YapMessageEdges.buddy destinationKey:uniqueBuddyId collection:[YapContact collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop) {
        [transaction removeObjectForKey:edge.sourceKey inCollection:edge.sourceCollection];
    }];

    // Update Last message date for sorting and grouping
    buddy.lastMessageDate = temp;
    [buddy saveWithTransaction:transaction];
}

+ (void)receivedDeliveryReceiptForMessageId:(NSString *)messageId transaction:(YapDatabaseReadWriteTransaction*)transaction {
    __block YapMessage *deliveredMessage = nil;
    [self enumerateMessagesWithMessageId:messageId transaction:transaction usingBlock:^(YapMessage *message, BOOL *stop) {
        if (message && message.isIncoming) {
            deliveredMessage = message;
            *stop = YES;
        }
    }];

    if (deliveredMessage) {
        deliveredMessage.delivered = YES;
        [deliveredMessage saveWithTransaction:transaction];
    }
}

+ (void)showLocalNotificationForMessage:(YapMessage *)message {
    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //            NSString * rawMessage = [message.text stringByConvertingHTMLToPlainText];
            //            // We are not active, so use a local notification instead
            //            __block ContactBusiness *localBuddy = nil;
            //            __block OTRAccount *localAccount;
            //            __block NSInteger unreadCount = 0;
            //            [[DatabaseManager sharedInstance].readOnlyDatabaseConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
            //                localBuddy = [message buddyWithTransaction:transaction];
            //                localAccount = [localBuddy accountWithTransaction:transaction];
            //                unreadCount = [self numberOfUnreadMessagesWithTransaction:transaction];
            //            }];
            //
            //            NSString *name = localBuddy.username;
            //            if ([localBuddy.displayName length]) {
            //                name = localBuddy.displayName;
            //            }
            //
            //            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            //            localNotification.alertAction = REPLY_STRING;
            //            localNotification.soundName = UILocalNotificationDefaultSoundName;
            //            localNotification.applicationIconBadgeNumber = unreadCount;
            //            localNotification.alertBody = [NSString stringWithFormat:@"%@: %@",name,rawMessage];
            //
            //            localNotification.userInfo = @{kOTRNotificationBuddyUniqueIdKey:localBuddy.uniqueId};
            //
            //            [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        });
    }
}

+ (void)enumerateMessagesWithMessageId:(NSString *)messageId transaction:(YapDatabaseReadTransaction *)transaction usingBlock:(void (^)(YapMessage *message,BOOL *stop))block;
{
    if ([messageId length] && block) {
        NSString *queryString = [NSString stringWithFormat:@"Where %@ = ?", YapDatabaseMessageIdSecondaryIndex];
        YapDatabaseQuery *query = [YapDatabaseQuery queryWithFormat:queryString, messageId];
        [[transaction ext:YapDatabaseMessageIdSecondaryIndexExtension] enumerateKeysMatchingQuery:query usingBlock:^(NSString *collection, NSString *key, BOOL *stop) {
            YapMessage *message = [YapMessage fetchObjectWithUniqueID:key transaction:transaction];
            if (message) {
                block(message,stop);
            }
        }];
    }
}

- (void)touchMessageWithTransaction:(YapDatabaseReadWriteTransaction *)transaction {
    [transaction touchObjectForKey:self.uniqueId inCollection:[YapMessage collection]];
}

- (void)touchMessage {
    [[DatabaseManager sharedInstance].newConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
        [self touchMessageWithTransaction:transaction];
    }];
}

@end
