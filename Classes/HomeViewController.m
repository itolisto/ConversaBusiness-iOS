//
//  HomeViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 12/9/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "HomeViewController.h"

#import "Colors.h"
#import "UIStateButton.h"

@interface HomeViewController ()

@property (weak, nonatomic) IBOutlet UIStateButton *loginButton;
@property (weak, nonatomic) IBOutlet UIStateButton *signupButton;

@end

@implementation HomeViewController

#pragma mark - Lifecycle Method -

- (void)viewDidLoad {
    [super viewDidLoad];
    // Add login button properties
    [self.loginButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.loginButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
    [self.loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    // Add sign up button properties
    [self.signupButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.signupButton setTitleColor:[Colors white] forState:UIControlStateNormal];
    [self.signupButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.signupButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
}

@end
