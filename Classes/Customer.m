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

@end
