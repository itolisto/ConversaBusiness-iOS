//
//  RegisterCompleteViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/27/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "RegisterCompleteViewController.h"

#import "Colors.h"
#import "UIStateButton.h"
#import "MBProgressHUD.h"
#import "JVFloatLabeledTextField.h"

@interface RegisterCompleteViewController ()
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *emailTextField;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *countryTextField;
@property (weak, nonatomic) IBOutlet UIStateButton *registerButton;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@end

@implementation RegisterCompleteViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    // Hide keyboard when pressed outside TextField
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    tap.delegate = self;
    // Add delegates
    self.emailTextField.delegate = self;
    self.passwordTextField.delegate = self;
    self.countryTextField.delegate = self;
    // Add button properties
    [self.registerButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.registerButton setTitleColor:[Colors white] forState:UIControlStateNormal];
    [self.registerButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.registerButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Observer Methods -

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary *info = aNotification.userInfo;

    CGRect rawFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, 140.0, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void) dismissKeyboard {
    //Causes the view (or one of its embedded text fields) to resign the first responder status.
    [self.view endEditing:YES];
}

#pragma mark - Action Methods -

- (IBAction)backButtonPressed:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)registerButtonPressed:(UIStateButton *)sender {
    
}

#pragma mark - UITextFieldDelegate Method -

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [self.countryTextField becomeFirstResponder];
    } else {

    }

    return YES;
}

#pragma mark - Register Methods -

//- (BOOL) validForm {
//    MBProgressHUD *hudError = [[MBProgressHUD alloc] initWithView:self.view];
//    hudError.mode = MBProgressHUDModeText;
//    [self.view addSubview:hudError];
//
//    if(isEmailValid([self.emailTextField text])) {
//        if([self.passwordTextField hasText]) {
//            [hudError removeFromSuperview];
//            return YES;
//        } else {
//            hudError.label.text = NSLocalizedString(@"signup_password_length_error", nil);
//            [hudError showAnimated:YES];
//            [hudError hideAnimated:YES afterDelay:1.7];
//            [self.passwordTextField becomeFirstResponder];
//        }
//    } else {
//        hudError.label.text = NSLocalizedString(@"sign_email_not_valid_error", nil);
//        [hudError showAnimated:YES];
//        [hudError hideAnimated:YES afterDelay:1.7];
//        [self.emailTextField becomeFirstResponder];
//    }
//
//    return NO;
//}
//
//- (void) doRegister {
//    if([self validForm]) {
//        Account *user = [Account object];
//        NSArray *emailPieces = [self.emailTextField.text componentsSeparatedByString: @"@"];
//        user.username = [emailPieces objectAtIndex: 0];
//        user.email = self.emailTextField.text;
//        user.password = self.passwordTextField.text;
//        // Extra fields
//        user[kUserTypeKey] = @(2);
//
//        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
//
//        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//            [MBProgressHUD hideHUDForView:self.view animated:YES];
//            if (!error) {
//                // Register successful
//                [LoginHandler proccessLoginForAccount:[Account currentUser] fromViewController:self];
//            } else {
//                // Show the errorString somewhere and let the user try again.
//                [self showErrorMessage];
//            }
//        }];
//    }
//}
//
//- (void) showErrorMessage {
//    UIAlertController * view=   [UIAlertController
//                                 alertControllerWithTitle:nil
//                                 message:NSLocalizedString(@"signup_failed_message", nil)
//                                 preferredStyle:UIAlertControllerStyleAlert];
//
//    UIAlertAction* ok = [UIAlertAction
//                         actionWithTitle:@"Ok"
//                         style:UIAlertActionStyleDefault
//                         handler:^(UIAlertAction * action) {
//                             [view dismissViewControllerAnimated:YES completion:nil];
//                         }];
//    [view addAction:ok];
//    [self presentViewController:view animated:YES completion:nil];
//}

@end
