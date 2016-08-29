//
//  RegisterViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 11/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "RegisterViewController.h"

#import "Log.h"
#import "Account.h"
#import "Customer.h"
#import "Constants.h"
#import "Utilities.h"
#import "LoginHandler.h"
#import "MBProgressHUD.h"
#import "JVFloatLabeledTextField.h"

@interface RegisterViewController ()

@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *emailTextField;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *termsLabel;
@property (weak, nonatomic) IBOutlet UILabel *termsBottomLabel;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;

@end

@implementation RegisterViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.emailTextField.placeholder = NSLocalizedString(@"email", nil);
    self.passwordTextField.placeholder = NSLocalizedString(@"password", nil);
    [self.signUpButton setTitle:NSLocalizedString(@"send_password_button", nil) forState:UIControlStateNormal];
    self.termsLabel.text = NSLocalizedString(@"signup_terms1_notification", nil);
    self.termsBottomLabel.text = NSLocalizedString(@"signup_terms2_notification", nil);
    
    // Hide keyboard when pressed outside TextField
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    tap.delegate = self;
    // Add delegates
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissKeyboard {
    // Causes the view (or one of its embedded text fields) to resign the first responder status.
    [self.view endEditing:YES];
}

#pragma mark - IBAction Methods -

- (IBAction)registerButtonPressed:(UIButton *)sender {
    [self doRegister];
}

- (IBAction)backBarButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate Method -

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else {
        [self doRegister];
    }
    
    return YES;
}

#pragma mark - Register Methods -

- (BOOL)validForm {
    MBProgressHUD *hudError = [[MBProgressHUD alloc] initWithView:self.view];
    hudError.mode = MBProgressHUDModeText;
    [self.view addSubview:hudError];
    
    if(isEmailValid([self.emailTextField text])) {
        if([self.passwordTextField hasText]) {
            [hudError removeFromSuperview];
            return YES;
        } else {
            hudError.labelText = NSLocalizedString(@"signup_password_length_error", nil);
            [hudError show:YES];
            [hudError hide:YES afterDelay:1.7];
            [self.passwordTextField becomeFirstResponder];
        }
    } else {
        hudError.labelText = NSLocalizedString(@"sign_email_not_valid_error", nil);
        [hudError show:YES];
        [hudError hide:YES afterDelay:1.7];
        [self.emailTextField becomeFirstResponder];
    }
    
    return NO;
}

- (void)doRegister {
    if([self validForm]) {
        Account *user = [Account object];
        NSArray *emailPieces = [self.emailTextField.text componentsSeparatedByString: @"@"];
        user.username = [emailPieces objectAtIndex: 0];
        user.email = self.emailTextField.text;
        user.password = self.passwordTextField.text;
        // Extra fields
        user[kUserTypeKey] = @(2);
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (!error) {
                // Register successful
                [LoginHandler proccessLoginForAccount:[Account currentUser] fromViewController:self];
            } else {
                // Show the errorString somewhere and let the user try again.
                [self showErrorMessage];
            }
        }];
    }
}

- (void)showErrorMessage {
    UIAlertController * view=   [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:NSLocalizedString(@"signup_failed_message", nil)
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"Ok"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action) {
                             [view dismissViewControllerAnimated:YES completion:nil];
                         }];
    [view addAction:ok];
    [self presentViewController:view animated:YES completion:nil];
}

@end
