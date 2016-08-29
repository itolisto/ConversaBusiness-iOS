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

@property (nonatomic, strong) Account *customerInfo;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) PFFile   *avatar;
@property (nonatomic, strong) NSString *status;

@end
