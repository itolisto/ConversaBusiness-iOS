//
//  YapAccount.h
//  Conversa
//
//  Created by Edgar Gomez on 12/23/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "YapDatabaseObject.h"

@interface YapAccount : YapDatabaseObject

@property (nonatomic, strong) NSString *uniqueDeviceId;
+ (void)deleteAccountWithTransaction:(YapDatabaseReadWriteTransaction*)transaction;
+ (NSString *)getUniqueDeviceId;

@end
