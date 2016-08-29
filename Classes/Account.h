//
//  Account.h
//  Conversa
//
//  Created by Edgar Gomez on 12/15/15.
//  Copyright © 2015 Conversa. All rights reserved.
//


@import Foundation;
#import <Parse/Parse.h>

@interface Account : PFUser

+ (NSString *)parseClassName;
- (NSString *)getPrivateChannel;
- (NSString *)getPublicChannel;

@property (nonatomic, strong) NSString *email;

@end
