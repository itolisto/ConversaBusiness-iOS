//
//  BusinessEmptyListViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/27/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "BusinessEmptyListViewController.h"

#import "Colors.h"
#import "UIStateButton.h"

@interface BusinessEmptyListViewController ()

@property (weak, nonatomic) IBOutlet UIStateButton *registerButton;

@end

@implementation BusinessEmptyListViewController

#pragma mark - Lifecycle Method -

- (void)viewDidLoad {
    [super viewDidLoad];
    // Add button properties
    [self.registerButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.registerButton setTitleColor:[Colors white] forState:UIControlStateNormal];
    [self.registerButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.registerButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
}

#pragma mark - Navigation Method -

- (IBAction)backButtonPressed:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
