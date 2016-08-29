//
//  Business.h
//  Conversa
//
//  Created by Edgar Gomez on 12/15/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import Foundation;
#import "Account.h"
#import <Parse/Parse.h>

@interface Business : PFObject<PFSubclassing>

+ (NSString *)parseClassName;

@property (nonatomic, strong) Account *businessInfo;
@property (nonatomic, strong) NSString *conversaID;
@property (nonatomic, strong) NSString *about;
@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) PFFile   *avatar;

@end
