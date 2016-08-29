//
//  Business.m
//  Conversa
//
//  Created by Edgar Gomez on 12/15/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "Business.h"

#import "Constants.h"
#import <Parse/PFObject+Subclass.h>

@implementation Business

@dynamic businessInfo;
@dynamic conversaID;
@dynamic about;
@dynamic status;
@dynamic displayName;
@dynamic avatar;

+ (void)load {
    [self registerSubclass];
}

+ (NSString *)parseClassName {
    return kClassBusiness;
}

@end