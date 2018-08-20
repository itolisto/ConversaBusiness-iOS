//
//  Customer.h
//  Conversa
//
//  Created by Edgar Gomez on 12/15/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import Foundation;

@class Customer;

typedef void (^CustomerQueryResult)(Customer *_Nullable object, NSError *_Nullable error);

@interface Customer : NSObject

+ (void)queryForCustomer:(NSString* _Nonnull)customerId block:(CustomerQueryResult _Nonnull)block;

@property (nonatomic, strong) NSString *objectId;
@property (nonatomic, strong) NSString * _Nullable displayName;

@end
