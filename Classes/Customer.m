//
//  Customer.m
//  Conversa
//
//  Created by Edgar Gomez on 12/15/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "Customer.h"

#import "Constants.h"
#import <Parse/PFObject+Subclass.h>

@implementation Customer

@dynamic displayName;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return kClassCustomer;
}

+ (void)queryForCustomer:(NSString*)customerId block:(CustomerQueryResult)block {
    PFQuery *query = [Customer query];
    [query whereKey:kCustomerActiveKey equalTo:@(YES)];
    [query selectKeys:@[kCustomerDisplayNameKey]];
    [query getObjectInBackgroundWithId:customerId
                                 block:^(PFObject * _Nullable object, NSError * _Nullable error)
     {
         if (error) {
             block(nil, error);
         } else {
             block((Customer*)object, nil);
         }
     }];
}

@end
