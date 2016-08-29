//
//  YapTag.h
//  ConversaBusiness
//
//  Created by Edgar Gomez on 3/28/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "YapDatabaseObject.h"
#import <YapDatabase/YapDatabaseRelationshipNode.h>

extern const struct YapTagEdges {
    __unsafe_unretained NSString *accountUniqueId;
} YapTagEdges;

@interface YapTag : YapDatabaseObject <YapDatabaseRelationshipNode>

@property (nonatomic, strong) NSString *tag;
@property (nonatomic, strong) NSString *accountUniqueId;

+ (void)deleteAllTags;
+ (NSArray *)getAllTagsWithTransaction:(YapDatabaseReadTransaction *)transaction;
+ (void)findAndDeleteTagWithText:(NSString *)text andTransaction:(YapDatabaseReadTransaction *)transaction;

@end
