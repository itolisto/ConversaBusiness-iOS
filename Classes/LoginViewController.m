//
//  LoginViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 11/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "LoginViewController.h"

#import "Log.h"
#import "Colors.h"
#import "Account.h"
#import "Constants.h"
#import "Utilities.h"
#import "LoginHandler.h"
#import "UIStateButton.h"
#import "MBProgressHUD.h"
#import "JVFloatLabeledTextField.h"

@interface LoginViewController ()

@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *emailTextField;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIStateButton *signinButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) UITextField *activeTextField;

@end

@implementation LoginViewController

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
    // Add login button properties
    [self.signinButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.signinButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.signinButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.signinButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
    // Init scroll state
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
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
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    if (self.activeTextField) {
        // If active text field is hidden by keyboard, scroll it so it's visible
        // Your app might not need or want this behavior.
        CGRect aRect = self.view.frame;
        aRect.size.height -= kbSize.height;

        if (!CGRectContainsPoint(aRect, self.activeTextField.frame.origin) ) {
            [self.scrollView scrollRectToVisible:self.activeTextField.frame animated:YES];
        }
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - Action Methods -

- (IBAction)loginButtonPressed:(UIButton *)sender {
    if ([self validateTextField:self.emailTextField text:self.emailTextField.text select:YES] &&
        [self validateTextField:self.passwordTextField text:self.passwordTextField.text select:YES])
    {
        [self doLogin];
    }
}

#pragma mark - UITextFieldDelegate Methods -

- (BOOL)validateTextField:(JVFloatLabeledTextField*)textField text:(NSString*)text select:(BOOL)select {
    if (textField == self.emailTextField) {
        if (isEmailValid(text)) {
            return YES;
        } else {
            MBProgressHUD *hudError = [[MBProgressHUD alloc] initWithView:self.view];
            hudError.mode = MBProgressHUDModeText;
            [self.view addSubview:hudError];

            if ([text isEqualToString:@""]) {
                hudError.label.text = NSLocalizedString(@"common_field_required", nil);
            } else {
                hudError.label.text = NSLocalizedString(@"common_field_invalid", nil);
            }

            [hudError showAnimated:YES];
            [hudError hideAnimated:YES afterDelay:1.7];

            if (select) {
                if (![textField isFirstResponder]) {
                    [textField becomeFirstResponder];
                }
            }

            return NO;
        }
    } else {
        if ([text isEqualToString:@""]) {
            MBProgressHUD *hudError = [[MBProgressHUD alloc] initWithView:self.view];
            hudError.mode = MBProgressHUDModeText;
            [self.view addSubview:hudError];
            hudError.label.text = NSLocalizedString(@"common_field_required", nil);
            [hudError showAnimated:YES];
            [hudError hideAnimated:YES afterDelay:1.7];

            if (select) {
                if (![textField isFirstResponder]) {
                    [textField becomeFirstResponder];
                }
            }

            return NO;
        } else {
            return YES;
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.activeTextField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }

    return YES;
}

#pragma mark - Login Methods -

- (void)doLogin {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    // TODO: Replace with FIREBASE
//    [Account logInWithUsernameInBackground:self.emailTextField.text
//                                  password:self.passwordTextField.text
//                                     block:^(PFUser * _Nullable user, NSError * _Nullable error)
//     {
//         [MBProgressHUD hideHUDForView:self.view animated:YES];
//         if(user) {
//             // Successful login
//             [LoginHandler proccessLoginForAccount:[Account currentUser] fromViewController:self];
//         } else {
//             // The login failed. Check error to see why
//             [self showErrorMessage];
//         }
//     }];
}

- (void)showErrorMessage {
    UIAlertController * view = [UIAlertController
                                alertControllerWithTitle:nil
                                message:NSLocalizedString(@"sign_failed_message", nil)
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

#pragma mark - Navigation Method -

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
