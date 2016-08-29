//
//  YapTag.m
//  ConversaBusiness
//
//  Created by Edgar Gomez on 3/28/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "YapTag.h"

#import "Account.h"
#import "YapAccount.h"
#import "DatabaseView.h"
#import "DatabaseManager.h"

const struct YapTagEdges YapTagEdges = {
    .accountUniqueId = @"accountUniqueId"
};

@implementation YapTag

#pragma mark - YapDatabaseRelationshipNode
// This method gets automatically called when the object is inserted/updated in the database.
- (NSArray *)yapDatabaseRelationshipEdges
{
    NSArray *edges = nil;
    
    if (self.accountUniqueId) {
        YapDatabaseRelationshipEdge *accountEdge = [YapDatabaseRelationshipEdge edgeWithName:YapTagEdges.accountUniqueId
                                                                              destinationKey:self.accountUniqueId
                                                                                  collection:[YapAccount collection]
                                                                             nodeDeleteRules:YDB_DeleteSourceIfDestinationDeleted];
        // YDB_DeleteSourceIfDestinationDeleted
        //   automatically delete this Tag if the Account is deleted
        edges = @[accountEdge];
    }
    
    return edges;
}

+ (void) deleteAllTags {
    [[DatabaseManager sharedInstance].newConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        [transaction removeAllObjectsInCollection:[YapTag collection]];
    }];
}

+ (NSArray *)getAllTagsWithTransaction:(YapDatabaseReadTransaction *)transaction {
    __block NSMutableArray* tagArray = [[NSMutableArray alloc] init];
    
    [[transaction ext:YapDatabaseRelationshipName] enumerateEdgesWithName:YapTagEdges.accountUniqueId destinationKey:[Account currentUser].objectId collection:[YapAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop)
     {
         YapTag *tag = [YapTag fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
         if (tag) {
             [tagArray addObject:tag];
         }
     }];
    
    return [tagArray copy];
}

+ (void)findAndDeleteTagWithText:(NSString *)text andTransaction:(YapDatabaseReadWriteTransaction *)transaction {
    [[transaction ext:YapDatabaseRelationshipName] enumerateEdgesWithName:YapTagEdges.accountUniqueId destinationKey:[Account currentUser].objectId collection:[YapAccount collection] usingBlock:^(YapDatabaseRelationshipEdge *edge, BOOL *stop)
     {
         YapTag *tag = [YapTag fetchObjectWithUniqueID:edge.sourceKey transaction:transaction];
         if ([tag.tag isEqualToString:text]) {
             [tag removeWithTransaction:transaction];
         }
     }];
}

@end
