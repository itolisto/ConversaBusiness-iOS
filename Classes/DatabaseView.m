//
//  DatabaseView.h
//  Conversa
//
//  Created by Edgar Gomez on 7/18/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

/*
 * NOTES
 *
 * 1. If you make changes to the groupingBlock and/or sortingBlock, then just change the versionTag, and
 * the view will automatically re-populate itself.
 * 2. You can register & unregister extensions at any time, even while you're actively using the database.
 * 3.
 */

#import "DatabaseView.h"

@import YapDatabase;
#import "YapMessage.h"
#import "YapContact.h"
#import "DatabaseManager.h"
#import <YapDatabase/YapDatabaseView.h>
#import <YapDatabase/YapDatabaseFilteredView.h>
#import <YapDatabase/YapDatabaseFullTextSearch.h>
#import <YapDatabase/YapDatabaseSecondaryIndex.h>
#import <YapDatabase/YapDatabaseSearchResultsView.h>

NSString *const ConversaDatabaseViewExtensionName = @"ConversaDatabaseViewExtensionName";
NSString *const ChatDatabaseViewExtensionName = @"ChatDatabaseViewExtensionName";
NSString *const UnreadConversationsViewExtensionName = @"UnreadConversationsViewExtensionName";
NSString *const BlockedDatabaseViewExtensionName = @"BlockedDatabaseViewExtension";
NSString *const RecentSearhDatabaseViewExtensionName = @"RecentSearhDatabaseViewExtensionName";
NSString *const ChatSearchDatabaseViewExtensionName = @"ChatSearchDatabaseViewExtensionName";

NSString *const SearchChatFTSExtensionName = @"SearchChatFTSExtensionName";

NSString *const YapDatabaseRelationshipName = @"YapDatabaseRelationshipName";
NSString *const YapDatabaseMessageIdSecondaryIndex = @"YapDatabaseMessageIdSecondaryIndex";
NSString *const YapDatabaseMessageIdSecondaryIndexExtension = @"YapDatabaseMessageIdSecondaryIndexExtension";

NSString *const ConversationGroup = @"Conversation";
NSString *const RecentSearchGroup = @"RecentSearchGroup";
NSString *const BlockedGroup = @"BlockedGroup";

@implementation DatabaseView

+ (void)registerRelationshipDatabase
{
    YapDatabaseRelationship *databaseRelationship = [[YapDatabaseRelationship alloc] initWithVersionTag:@"1"
                                                                                                options:nil];

    [[DatabaseManager sharedInstance].database registerExtension:databaseRelationship
                                                        withName:YapDatabaseRelationshipName];
}

+ (void)registerConversationDatabaseView
{
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString * _Nullable(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object)
                                             {
                                                 if ([object isKindOfClass:[YapContact class]]) {
                                                     __weak YapContact *buddy = (YapContact *)object;
                                                     if (buddy.lastMessageDate) {
                                                         return ConversationGroup;
                                                     }
                                                 }

                                                 return nil; // Exclude from view
                                             }];

    // After the view invokes the grouping block to determine what group a
    // database row belongs to (if any), the view then needs to determine
    // what index within that group the row should be.
    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group,
                                                                                                      NSString * _Nonnull collection1, NSString * _Nonnull key1, id  _Nonnull object1,
                                                                                                      NSString * _Nonnull collection2, NSString * _Nonnull key2, id  _Nonnull object2)
                                           {
                                               // The "group" parameter comes from your grouping block
                                               if ([object1 isKindOfClass:[YapContact class]] && [object2 isKindOfClass:[YapContact class]]) {
                                                   __weak YapContact *buddy1 = (YapContact *)object1;
                                                   __weak YapContact *buddy2 = (YapContact *)object2;

                                                   return [buddy2.lastMessageDate compare:buddy1.lastMessageDate];
                                               }

                                               return NSOrderedSame;
                                           }];

    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    // Primary motivation for this is to reduce the overhead when first populating the view
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[YapContact collection]]];

    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                                      sorting:viewSorting
                                                                   versionTag:@"1"
                                                                      options:options];

    [[DatabaseManager sharedInstance].database asyncRegisterExtension:databaseView
                                                             withName:ConversaDatabaseViewExtensionName
                                                      completionBlock:^(BOOL ready)
     {
         [self registerUnreadConversationsView];
         [self registerBlockedDatabaseView];
         [self registerChatSearchingDatabaseView];
     }];
}

+ (void)registerChatDatabaseView
{
    YapDatabaseViewGrouping *viewGrouping = [YapDatabaseViewGrouping withObjectBlock:^NSString * _Nullable(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object)
                                             {
                                                 if ([object isKindOfClass:[YapMessage class]]) {
                                                     return ((YapMessage *)object).buddyUniqueId;
                                                 }

                                                 return nil;
                                             }];

    YapDatabaseViewSorting *viewSorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group,
                                                                                                      NSString * _Nonnull collection1, NSString * _Nonnull key1, id  _Nonnull object1,
                                                                                                      NSString * _Nonnull collection2, NSString * _Nonnull key2, id  _Nonnull object2)
                                           {
                                               if ([object1 isKindOfClass:[YapMessage class]] && [object2 isKindOfClass:[YapMessage class]]) {
                                                   __weak YapMessage *message1 = (YapMessage *)object1;
                                                   __weak YapMessage *message2 = (YapMessage *)object2;
                                                   return [message1.date compare:message2.date];
                                               }

                                               return NSOrderedSame;
                                           }];

    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = YES;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[YapMessage collection]]];

    YapDatabaseView *view = [[YapDatabaseView alloc] initWithGrouping:viewGrouping
                                                              sorting:viewSorting
                                                           versionTag:@"1"
                                                              options:options];

    [[DatabaseManager sharedInstance].database asyncRegisterExtension:view
                                                             withName:ChatDatabaseViewExtensionName
                                                      completionBlock:nil];
}

+ (void)registerUnreadConversationsView
{
    YapDatabaseViewFiltering *viewFiltering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object)

    {
        NSInteger numberOfUnreadMessages = [((YapContact*)object) numberOfUnreadMessagesWithTransaction:transaction];
        return (numberOfUnreadMessages > 0);
    }];

    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = NO;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[YapContact collection]]];

    YapDatabaseFilteredView *filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:ConversaDatabaseViewExtensionName
                                                                                          filtering:viewFiltering
                                                                                         versionTag:@"1"
                                                                                            options:options];

    // Before you can register the FilteredView, you must first register its parent view
    [[DatabaseManager sharedInstance].database asyncRegisterExtension:filteredView
                                                             withName:UnreadConversationsViewExtensionName
                                                      completionBlock:nil];
}

+ (void)registerBlockedDatabaseView
{
    YapDatabaseViewFiltering *viewFiltering = [YapDatabaseViewFiltering withObjectBlock:^BOOL(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object)
                                               {
                                                   return ((YapContact*)object).blocked;
                                               }];

    YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
    options.isPersistent = NO;
    options.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[YapContact collection]]];

    YapDatabaseFilteredView *filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:ConversaDatabaseViewExtensionName
                                                                                          filtering:viewFiltering
                                                                                         versionTag:@"1"
                                                                                            options:options];

    [[DatabaseManager sharedInstance].database asyncRegisterExtension:filteredView
                                                             withName:BlockedDatabaseViewExtensionName
                                                      completionBlock:nil];
}

+ (void)registerChatSearchingDatabaseView {
    NSArray *propertiesToIndexForMySearch = @[YapContactAttributes.displayName];

    YapDatabaseFullTextSearchHandler *handler = [YapDatabaseFullTextSearchHandler withObjectBlock:^(NSMutableDictionary *dict, NSString *collection, NSString *key, id object)
                                                 {
                                                     if ([object isKindOfClass:[YapContact class]]) {
                                                         __weak YapContact *person = (YapContact *)object;
                                                         dict[YapContactAttributes.displayName] = person.displayName;
                                                     }
                                                 }];

    YapDatabaseFullTextSearch *fts = [[YapDatabaseFullTextSearch alloc] initWithColumnNames:propertiesToIndexForMySearch
                                                                                    handler:handler
                                                                                 versionTag:@"1"];

    [[DatabaseManager sharedInstance].database asyncRegisterExtension:fts
                                                             withName:ChatSearchDatabaseViewExtensionName
                                                      completionBlock:^(BOOL ready)
     {
         if (ready) {
             // Create the search view.
             // This extension allows you to use an existing FTS extension, perform searches on it,
             // and then pipe the search results into a regular view.
             //
             // There are a couple ways we can set this up:
             // - Use the FTS module to search an existing view
             // - Just use the FTS module, and provide a groupingBlock/sortingBlock to order the results
             //
             // In our case, we want to use the FTS module in order to search the main view.
             // So we're going to setup the search view accordingly.
             
             YapDatabaseSearchResultsViewOptions *searchViewOptions = [[YapDatabaseSearchResultsViewOptions alloc] init];
             searchViewOptions.isPersistent = NO;
             searchViewOptions.allowedCollections = [[YapWhitelistBlacklist alloc] initWithWhitelist:[NSSet setWithObject:[YapContact collection]]];
             
             YapDatabaseSearchResultsView *searchResultsView = [[YapDatabaseSearchResultsView alloc]
                                                                initWithFullTextSearchName:ChatSearchDatabaseViewExtensionName
                                                                parentViewName:ConversaDatabaseViewExtensionName
                                                                versionTag:@"1"
                                                                options:searchViewOptions];
             
             [[DatabaseManager sharedInstance].database asyncRegisterExtension:searchResultsView
                                                                      withName:SearchChatFTSExtensionName
                                                               completionBlock:nil];
         }
     }];
}

+ (void)registerSecondaryIndexes {
    YapDatabaseSecondaryIndexSetup *setup = [[YapDatabaseSecondaryIndexSetup alloc] init];
    [setup addColumn:YapDatabaseMessageIdSecondaryIndex withType:YapDatabaseSecondaryIndexTypeText];
    
    YapDatabaseSecondaryIndexHandler *indexHandler = [YapDatabaseSecondaryIndexHandler withObjectBlock:^(YapDatabaseReadTransaction * _Nonnull transaction, NSMutableDictionary * _Nonnull dict,
                                                                                                         NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object)
                                                      {
                                                          if ([object isKindOfClass:[YapMessage class]]) {
                                                              dict[YapDatabaseMessageIdSecondaryIndex] = ((YapMessage *)object).uniqueId;
                                                          }
                                                      }];
    
    YapDatabaseSecondaryIndex *secondaryIndex = [[YapDatabaseSecondaryIndex alloc] initWithSetup:setup handler:indexHandler];
    
    [[DatabaseManager sharedInstance].database asyncRegisterExtension:secondaryIndex
                                                             withName:YapDatabaseMessageIdSecondaryIndexExtension
                                                      completionBlock:nil];
}

@end
