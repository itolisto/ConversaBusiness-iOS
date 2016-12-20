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

@interface Customer : PFObject<PFSubclassing>

+ (NSString *)parseClassName;

@property (nonatomic, strong) NSString *displayName;

@end
