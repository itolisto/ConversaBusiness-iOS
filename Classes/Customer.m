//
//  Customer.m
//  Conversa
//
//  Created by Edgar Gomez on 12/15/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "Customer.h"

#import "Constants.h"

@implementation Customer

+ (void)queryForCustomer:(NSString*)customerId block:(CustomerQueryResult)block {
    // TODO: Replace with networking layer
//    PFQuery *query = [Customer query];
//    [query whereKey:kCustomerActiveKey equalTo:@(YES)];
//    [query selectKeys:@[kCustomerDisplayNameKey]];
//    [query getObjectInBackgroundWithId:customerId
//                                 block:^(PFObject * _Nullable object, NSError * _Nullable error)
//     {
//         if (error) {
//             block(nil, error);
//         } else {
//             block((Customer*)object, nil);
//         }
//     }];
}

@end
