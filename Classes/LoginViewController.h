//
//  LoginViewController.h
//  Conversa
//
//  Created by Edgar Gomez on 11/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

@import UIKit;
@class Account;

@interface LoginViewController : UIViewController <UIGestureRecognizerDelegate, UITextFieldDelegate>

@property (nonatomic, strong) Account *account;

@end
