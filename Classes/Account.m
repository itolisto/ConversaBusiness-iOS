//
//  Account.m
//  Conversa
//
//  Created by Edgar Gomez on 12/15/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "Account.h"

#import "YapAccount.h"
#import "DatabaseManager.h"
#import <Parse/PFObject+Subclass.h>

@implementation Account

@dynamic email;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return [super parseClassName];
}

+ (void)logOut {
    [[DatabaseManager sharedInstance].newConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
    {
        [YapAccount deleteAccountWithTransaction:transaction];
    }];
    [super logOut];
}

- (NSString *)getPrivateChannel {
    return [NSString stringWithFormat:@"%@_pvt", [self objectId]];
}

- (NSString *)getPublicChannel {
    return [NSString stringWithFormat:@"%@_pbc", [self objectId]];
}

@end
