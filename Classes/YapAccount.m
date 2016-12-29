//
//  YapAccount.m
//  Conversa
//
//  Created by Edgar Gomez on 12/23/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "YapAccount.h"

#import "Account.h"
#import "Constants.h"
#import "DatabaseManager.h"
#import "NSFileManager+Conversa.h"

@implementation YapAccount

+ (void)deleteAccountWithTransaction:(YapDatabaseReadWriteTransaction*)transaction {
    [[NSFileManager defaultManager] deleteDataInLibraryDirectory:kAccountAvatarName
                                                  inSubDirectory:kMessageMediaAvatarLocation
                                                           error:nil];
    // Automatically deletes all data in Database. This is done by taking
    // advantage from Relationships
    [transaction removeAllObjectsInCollection:[YapAccount collection]];
}

+ (NSString *)getUniqueDeviceId {
    __block NSString* uniqueId = @"";
    
    [[DatabaseManager sharedInstance].newConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        YapAccount *account = (YapAccount *)[transaction objectForKey:[Account currentUser].objectId
                                                         inCollection:[YapAccount collection]];
        uniqueId = account.uniqueDeviceId;
    }];
    
    return uniqueId;
}

@end
