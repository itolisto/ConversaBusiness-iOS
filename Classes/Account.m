//
//  Account.m
//  Conversa
//
//  Created by Edgar Gomez on 12/15/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "Account.h"

#import "EDQueue.h"
#import "YapAccount.h"
#import "DatabaseManager.h"
#import "CustomAblyRealtime.h"
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
    [[CustomAblyRealtime sharedInstance] logout];
    [[DatabaseManager sharedInstance].newConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
     {
         [YapAccount deleteAccountWithTransaction:transaction];
     }];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[EDQueue sharedInstance] empty];
    [super logOut];
}

@end
