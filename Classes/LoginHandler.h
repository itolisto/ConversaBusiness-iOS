//
//  LoginHandler.h
//  Conversa
//
//  Created by Edgar Gomez on 12/23/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import UIKit;
@class Account;

@interface LoginHandler : NSObject

+ (void) proccessLoginForAccount:(Account *)account fromViewController:(UIViewController*)controller;

@end
