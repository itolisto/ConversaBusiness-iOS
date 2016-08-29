//
//  YapContact.m
//  Off the Record
//
//  Created by David Chiles on 3/28/14.
//  Copyright (c) 2014 Chris Ballinger. All rights reserved.
//

#import "YapContact.h"

@import YapDatabase;
#import "Account.h"
#import "Constants.h"
#import "YapMessage.h"
#import "YapAccount.h"
#import "DatabaseView.h"
#import "DatabaseManager.h"
#import "NSFileManager+Conversa.h"

const struct YapContactAttributes YapContactAttributes = {
    .displayName = @"displayName"
};

const struct YapContactEdges YapContactEdges = {
    .account = @"accountUniqueId",
};

@implementation YapContact

- (void)removeWithTransaction:(YapDatabaseReadWriteTransaction *)transaction {
    // Remove avatar
    [[NSFileManager defaultManager] deleteDataInCachesDirectory:[self.uniqueId stringByAppendingString:@"_avatar.jpg"] inSubDirectory:kMessageMediaImageLocation error:nil];
    [super removeWithTransaction:transaction];
}

- (void)programActionInHours:(NSInteger)hours
                    isMuting:(BOOL)isMuting
{
    if(!isMuting) {
        // Eliminar accion futura
        NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];
        
        for(UILocalNotification *notification in notifications) {
            if(notification) {
                NSString *contact = [notification.userInfo objectForKey:kMuteUserNotificationName];
                
                if([contact isEqualToString:self.uniqueId]) {
                    [[UIApplication sharedApplication] cancelLocalNotification:notification];
                    
                    // Update badge
                    [UIApplication sharedApplication].applicationIconBadgeNumber = [[[UIApplication sharedApplication] scheduledLocalNotifications] count];
                    break;
                }
            }
        }
        
    } else {
        // Add future action
        NSDate *now = [NSDate date];
        NSTimeInterval secondsInHours = hours * 60 * 60;
        NSDate *dateHoursAhead = [now dateByAddingTimeInterval:secondsInHours];
        
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate  = dateHoursAhead;
        localNotification.alertBody = [NSString stringWithFormat:@"%@", self.displayName];
        localNotification.hasAction = NO;
        localNotification.applicationIconBadgeNumber = [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1;
        
        NSDictionary *infoDict = [NSDictionary dictionaryWithObject:self.uniqueId
                                                             forKey:kMuteUserNotificationName];
        
        localNotification.userInfo = infoDict;
        [[UIApplication sharedApplication]
         scheduleLocalNotification:localNotification];
    }
}

- (BOOL)hasMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction {
    NSUInteger numberOfMessages = [[transaction ext:YapDatabaseRelationshipName] edgeCountWithName:YapMessageEdges.buddy destinationKey:self.uniqueId collection:[YapContact collection]];
    
    return (numberOfMessages > 0);
}

- (NSInteger)numberOfUnreadMessagesWithTransaction:(YapDatabaseReadTransaction *)transaction {
    __block NSUInteger count = 0;
    [[transaction ext:YapDatabaseRelationshipName] enumerateEdgesWithName:YapMessageEdges.buddy destinationKey:self.uniqueId collection:[YapContact collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop)
     {
         YapMessage *message = [YapMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
         // Count only incoming messages
         if (message.isIncoming && !message.isView) {
             count += 1;
             *stop = YES;
         }
     }];
    
    return count;
}

- (YapAccount*)accountWithTransaction:(YapDatabaseReadTransaction *)transaction {
    return [YapAccount fetchObjectWithUniqueID:self.accountUniqueId transaction:transaction];
}

- (BOOL)setAllMessagesView:(YapDatabaseReadWriteTransaction *)transaction {
    __block BOOL dataChanged = NO;
    [[transaction ext:YapDatabaseRelationshipName] enumerateEdgesWithName:YapMessageEdges.buddy destinationKey:self.uniqueId collection:[YapContact collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop)
     {
         YapMessage *message = [[YapMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction] copy];
         
         if (message.isIncoming && !message.isView) {
             dataChanged = YES;
             message.view = YES;
             [message saveWithTransaction:transaction];
         }
     }];
    
    return dataChanged;
}

- (YapMessage *)lastMessageWithTransaction:(YapDatabaseReadTransaction *)transaction {
    __block YapMessage *finalMessage = nil;
    [[transaction ext:YapDatabaseRelationshipName] enumerateEdgesWithName:YapMessageEdges.buddy destinationKey:self.uniqueId collection:[YapContact collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop)
     {
         YapMessage *message = [YapMessage fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
         
         if (!finalMessage || [message.date compare:finalMessage.date] == NSOrderedDescending) {
             finalMessage = message;
             *stop = YES;
         }
     }];
    return [finalMessage copy];
}

- (NSString *)getPublicChannel {
    return [self.uniqueId stringByAppendingString:@"-pbc"];
}

- (NSString *)getPrivateChannel {
    return [self.uniqueId stringByAppendingString:@"-pvt"];
}

#pragma mark - YapDatabaseRelationshipNode
// This method gets automatically called when the object is inserted/updated in the database.
- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    
    if (self.accountUniqueId) {
        YapDatabaseRelationshipEdge *accountEdge = [YapDatabaseRelationshipEdge edgeWithName:YapContactEdges.account
                                                                              destinationKey:self.accountUniqueId
                                                                                  collection:[YapAccount collection]
                                                                             nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        // YDB_DeleteSourceIfDestinationDeleted
        //   automatically delete this Contact if the Account is deleted
        edges = @[accountEdge];
    }
    
    return edges;
}

#pragma mark - Class Methods

+ (NSUInteger)numberOfBlockedContacts {
    __block NSUInteger count = 0;
    
    [[DatabaseManager sharedInstance].newConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [transaction enumerateRowsInCollection:[YapContact collection] usingBlock:^(NSString * _Nonnull key, id  _Nonnull object, id  _Nullable metadata, BOOL * _Nonnull stop) {
            if (((YapContact*)object).mute) {
                count++;
            }
        }];
    }];
    
    return count;
}

+ (NSDictionary*) saveContactWithParseBusiness:(Customer *)business
                                 andConnection:(YapDatabaseConnection*)editingConnection
                                       andSave:(BOOL)save
{
    NSMutableDictionary *values = [[NSMutableDictionary alloc] init];
    __block YapContact *newBuddy = nil;
    
    if (!save) {
        [editingConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
            newBuddy = [transaction objectForKey:business.objectId inCollection:[YapContact collection]];
        }];
    }
    
    if (newBuddy) {
        // Update info. Maybe local data is out-of-date
        newBuddy.displayName = business.displayName;
        newBuddy.statusMessage = business.status;
        [editingConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            [newBuddy saveWithTransaction:transaction];
        }];
        [values setObject:[NSNumber numberWithBool:YES] forKey:kNSDictionaryChangeValue];
    } else {
        newBuddy = [[YapContact alloc] initWithUniqueId:business.objectId];
        newBuddy.accountUniqueId = [Account currentUser].objectId;
        newBuddy.displayName = business.displayName;
        newBuddy.statusMessage = business.status;
        newBuddy.composingMessageString = @"";
        newBuddy.blocked = NO;
        newBuddy.mute = NO;
        
        if (save) {
            [editingConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                [newBuddy saveWithTransaction:transaction];
            }];
            [values setObject:[NSNumber numberWithBool:YES] forKey:kNSDictionaryChangeValue];
        } else {
            [values setObject:[NSNumber numberWithBool:NO] forKey:kNSDictionaryChangeValue];
        }
        
        
    }
    
    [values setObject:[newBuddy copy] forKey:kNSDictionaryCustomer];
    
    return values;
}

@end
