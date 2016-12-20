//
//  HomeViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 12/9/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "HomeViewController.h"

#import "Colors.h"
#import "Constants.h"

@interface HomeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Add border to Button
    [[self.loginButton layer] setBorderWidth:1.0f];
    [[self.loginButton layer] setBorderColor:[Colors greenColor].CGColor];
    // Add circular borders
    [[self.loginButton layer] setCornerRadius:borderCornerRadius];
    [[self.signupButton layer] setCornerRadius:borderCornerRadius];
}

- (IBAction)clickHereButton:(UIButton *)sender {
    
}

@end
