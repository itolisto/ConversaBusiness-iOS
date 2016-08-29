//
//  DatabaseView.h
//  Conversa
//
//  Created by Edgar Gomez on 7/18/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import Foundation;
@import YapDatabase;

// Extension Strings
extern NSString *const ConversaDatabaseViewExtensionName;
extern NSString *const ChatDatabaseViewExtensionName;
extern NSString *const ChannelsDatabaseViewExtensionName;
extern NSString *const UnreadConversationsViewExtensionName;
extern NSString *const BlockedDatabaseViewExtensionName;
extern NSString *const RecentSearhDatabaseViewExtensionName;
extern NSString *const ChatSearchDatabaseViewExtensionName;

// FTS String
extern NSString *const SearchChatFTSExtensionName;

// Relationship String
extern NSString *const YapDatabaseRelationshipName;

// Secondary Index Strings
extern NSString *const YapDatabaseMessageIdSecondaryIndex;
extern NSString *const YapDatabaseMessageIdSecondaryIndexExtension;

// Group Strins
extern NSString *const ConversationGroup;
extern NSString *const RecentSearchGroup;
extern NSString *const BlockedGroup;

@interface DatabaseView : NSObject

+ (void)registerRelationshipDatabase;
+ (void)registerConversationDatabaseView;
+ (void)registerChatDatabaseView;
+ (void)registerSecondaryIndexes;

@end