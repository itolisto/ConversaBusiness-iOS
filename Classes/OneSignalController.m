//
//  OneSignalController.m
//  ConversaBusiness
//
//  Created by Edgar Gomez on 7/21/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "OneSignalController.h"

#import "YapContact.h"
#import "YapMessage.h"
#import "DatabaseManager.h"
@import Parse;

@implementation OneSignalController

+ (void)processMessage:(NSDictionary *)pnMessage userState:(BOOL)state setView:(BOOL)view {
    /*
     * Process:
     *
     * 1. Incoming message
     * 2. Account name changed [ok]
     * 3. Account conversa id changed [ok]
     * 4. Account status changed [ok]
     * 5. Account redirect changed [ok]
     * 6. Account categories changed [ok]
     * 7. Account verified changed [ok]
     * 8. Account plan changed [ok]
     *
     */

//    if (state) {
//        // NO DESCARGAR MENSAJE
//    } else {
//        
//        if (pnMessage.deviceId && [pnMessage.deviceId isEqualToString:[YapAccount getUniqueDeviceId]]) {
//            // Mensaje publicado por este dispositivo
//            return;
//        } else if ([SettingsKeys getSendToConversaSetting]) {
//            // Publish to PubNub channel and save message.read = YES; to YapDatabase
//            NSDictionary *messageNSD = @{
//                                         kPubNubMessageTextKey : pnMessage.message,
//                                         kPubNubMessageFromKey : pnMessage.from,
//                                         kPubNubMessageFromRedirectKey : [Account currentUser].objectId,
//                                         kPubNubMessageTypeKey : pnMessage.type
//                                         };
//            //PubNubMessage *redirectMessage = [[PubNubMessage alloc] initFromDictionary:messageNSD withTimeToken:nil];
//            
//            //[[PubNubService sharedInstance] sendMessageToChannel:@"va3qiR0xDf-private"
//            //                                             message:redirectMessage
//            //                                 withCompletionBlock:nil];
//            
//            return;
//        }
//        
//        PFQuery *query = [Message query];
//        NSInteger type = [pnMessage.type intValue];
//        
//        switch (type) {
//            case kMessageTypeText: {
//                [query selectKeys:@[kMessageTextKey]];
//                break;
//            }
//            case kMessageTypeLocation: {
//                [query selectKeys:@[kMessageLocationKey]];
//                break;
//            }
//            case kMessageTypeImage: {
//                [query selectKeys:@[kMessageFileKey, kMessageThumbKey, kMessageWidthKey, kMessageHeightKey]];
//                break;
//            }
//            case kMessageTypeAudio:
//            case kMessageTypeVideo: {
//                [query selectKeys:@[kMessageFileKey, kMessageThumbKey, kMessageDurationKey]];
//                break;
//            }
//        }
//        
//        [query whereKey:kObjectRowObjectIdKey equalTo:pnMessage.message];
//        
//        if (pnMessage.deviceId) {
//            [query whereKey:kMessageFromUserKey
//                    equalTo:[Account objectWithoutDataWithObjectId:MESSAGE_FROM_SENDERID]];
//            [query whereKey:kMessageToUserKey
//                    equalTo:[Account objectWithoutDataWithObjectId:pnMessage.from]];
//        } else {
//            [query whereKey:kMessageFromUserKey
//                    equalTo:[Account objectWithoutDataWithObjectId:pnMessage.from]];
//            [query whereKey:kMessageToUserKey
//                    equalTo:[Account objectWithoutDataWithObjectId:MESSAGE_FROM_SENDERID]];
//        }
//        
//        [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
//            if (error == nil) {
//                Message *parseMessage  = (Message *)object;
//                
//                YapMessage *newMessage = [[YapMessage alloc] init];
//                newMessage.view     = view;
//                newMessage.read     = view;
//                newMessage.incoming = (pnMessage.deviceId) ? NO : YES;
//                newMessage.delivered     = (pnMessage.deviceId) ? statusAllDelivered : statusReceived;
//                newMessage.messageType   = type;
//                newMessage.buddyUniqueId = pnMessage.from;
//                PFFile *file      = nil;
//                PFFile *thumbFile = nil;
//                
//                switch (type) {
//                    case kMessageTypeText: {
//                        newMessage.text       = parseMessage.text;
//                        break;
//                    }
//                    case kMessageTypeLocation: {
//                        newMessage.location   = [[CLLocation alloc]
//                                                 initWithLatitude:parseMessage.location.latitude
//                                                 longitude:parseMessage.location.longitude];
//                        newMessage.transferProgress = 100;
//                        break;
//                    }
//                    case kMessageTypeImage: {
//                        file      = parseMessage.file;
//                        thumbFile = parseMessage.thumbnail;
//                        newMessage.filename = parseMessage.file.name;
//                        newMessage.width    = [parseMessage.width  doubleValue];
//                        newMessage.height   = [parseMessage.height doubleValue];
//                        break;
//                    }
//                    case kMessageTypeAudio:
//                    case kMessageTypeVideo: {
//                        file      = parseMessage.file;
//                        thumbFile = parseMessage.thumbnail;
//                        newMessage.filename  = parseMessage.file.name;
//                        newMessage.duration  = parseMessage.duration;
//                        break;
//                    }
//                }
//                
//                YapDatabaseConnection *connection = [[DatabaseManager sharedInstance] newConnection];
//                __block YapContact *buddy = nil;
//                
//                [connection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
//                    buddy = [YapContact fetchObjectWithUniqueID:pnMessage.from transaction:transaction];
//                }];
//                
//                if (buddy) {
//                    // Contact already exists
//                    if (buddy.blocked) {
//                        // NO DESCARGAR MENSAJE
//                    } else {
//                        [self saveMessageWithUser:buddy connection:connection message:newMessage file:file thumbnail:thumbFile];
//                    }
//                } else {
//                    if (pnMessage.deviceId) {
//                        // No descarga informacion de cliente si este dispositivo aun no tiene una conversacion con él.
//                        return;
//                    }
//                    // Download contact info from Parse
//                    // TODO: Set more parameters to search because it may failed if
//                    // Parse class has more than 500,000 records
//                    PFQuery *bQuery = [Customer query];
//                    [bQuery whereKey:@"active" equalTo:@(YES)];
//                    [bQuery whereKey:@"userInfo" equalTo:[Account objectWithoutDataWithObjectId:pnMessage.from]];
//                    [bQuery includeKey:@"userInfo"];
//                    [bQuery getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
//                        if (error == nil) {
//                            NSDictionary *values = [YapContact saveContactWithParseBusiness:(Customer*)object
//                                                                              andConnection:connection
//                                                                                    andSave:YES];
//                            __block YapContact *newBuddy = (YapContact*)[values valueForKey:kNSDictionaryCustomer];
//                            
//                            [self saveMessageWithUser:newBuddy connection:connection message:newMessage file:file thumbnail:thumbFile];
//                        } else {
//                            // In this moment user isn't notified about message error download
//                        }
//                    }];
//                }
//            } else {
//                // In this moment user isn't notified about message error download
//            }
//        }];
//    }
}

+ (void)saveMessageWithUser:(YapContact*)contact connection:(YapDatabaseConnection*)connection message:(YapMessage*)message file:(PFFile*)file thumbnail:(PFFile*)thumb
{
//    if (file) {
//        NSInteger temp = message.delivered;
//        message.delivered = (temp == statusAllDelivered) ? statusUploading : statusDownloading;
//        
//        [file getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
//            if (error) {
//                message.transferProgress = 0;
//                message.error     = error.description;
//                message.delivered = statusReceivedError;
//            } else {
//                message.transferProgress = 100;
//                message.delivered = (temp == statusAllDelivered) ? statusAllDelivered : statusReceived;
//                
//                switch (message.messageType) {
//                    case kMessageTypeImage: {
//                        // Save to Cache Directory
//                        [[NSFileManager defaultManager] saveDataToCachesDirectory:data withName:file.name andDirectory:kMessageMediaImageLocation];
//                        break;
//                    }
//                    case kMessageTypeAudio: {
//                        // Save to Cache Directory
//                        [[NSFileManager defaultManager] saveDataToCachesDirectory:data withName:file.name andDirectory:kMessageMediaAudioLocation];
//                        break;
//                    }
//                    case kMessageTypeVideo: {
//                        // Save to Cache Directory
//                        [[NSFileManager defaultManager] saveDataToCachesDirectory:data withName:[file.name stringByAppendingString:@".mp4"] andDirectory:kMessageMediaVideoLocation];
//                        break;
//                    }
//                }
//            }
//            
//            [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
//                [message saveWithTransaction:transaction];
//                // Make a YapDatabaseModifiedNotification to update
//                NSDictionary *transactionExtendedInfo = @{YapDatabaseModifiedNotificationUpdate: @TRUE};
//                transaction.yapDatabaseModifiedNotificationCustomObject = transactionExtendedInfo;
//            }];
//        } progressBlock:^(int percentDone) {
//            message.transferProgress = percentDone;
//            [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
//                [message saveWithTransaction:transaction];
//            }];
//        }];
//        
//        [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
//            [message saveWithTransaction:transaction];
//        } completionBlock:^{
//            [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
//                contact.lastMessageDate = message.date;
//                [contact saveWithTransaction:transaction];
//            } completionBlock:^{
//                [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_CELL_NOTIFICATION_NAME
//                                                                    object:nil
//                                                                  userInfo:@{UPDATE_CELL_DIC_KEY: message.buddyUniqueId}];
//            }];
//        }];
//    } else {
//        // Is a text only message
//        [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
//            [message saveWithTransaction:transaction];
//        } completionBlock:^{
//            [connection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
//                contact.lastMessageDate = message.date;
//                [contact saveWithTransaction:transaction];
//            } completionBlock:^{
//                [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_CELL_NOTIFICATION_NAME
//                                                                    object:nil
//                                                                  userInfo:@{UPDATE_CELL_DIC_KEY: message.buddyUniqueId}];
//            }];
//        }];
//    }
}

@end
