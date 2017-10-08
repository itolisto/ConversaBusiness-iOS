//
//  Customer.h
//  Conversa
//
//  Created by Edgar Gomez on 12/15/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import Foundation;
#import "Account.h"
#import <Parse/Parse.h>

@class Customer;

typedef void (^CustomerQueryResult)(Customer *_Nullable object, NSError *_Nullable error);

@interface Customer : PFObject<PFSubclassing>

+ (NSString *_Nonnull)parseClassName;
+ (void)queryForCustomer:(NSString* _Nonnull)customerId block:(CustomerQueryResult _Nonnull)block;

@property (nonatomic, strong) NSString * _Nullable displayName;

@end
