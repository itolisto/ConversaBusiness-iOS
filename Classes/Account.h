//
//  Account.h
//  Conversa
//
//  Created by Edgar Gomez on 12/15/15.
//  Copyright © 2015 Conversa. All rights reserved.
//


@import Foundation;

@interface Account : NSObject

@property (nonatomic, strong) NSString *objectId;
@property (nonatomic, strong) NSString *email;

+ (Account*)currentUser;
+ (void)logOut;

@end
