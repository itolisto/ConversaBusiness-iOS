//
//  ContactViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/27/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "ContactViewController.h"

#import "Colors.h"
#import "Utilities.h"
#import "UIStateButton.h"
#import "MBProgressHUD.h"
#import "JVFloatLabeledTextField.h"
#import <Parse/Parse.h>

@interface ContactViewController ()

@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *nameTextField;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *emailTextField;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *businessTextField;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *contactTextField;
@property (weak, nonatomic) UITextField *activeTextField;
@property (weak, nonatomic) IBOutlet UIStateButton *contactButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation ContactViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    // Hide keyboard when pressed outside TextField
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    tap.delegate = self;
    // Add delegates
    self.nameTextField.delegate = self;
    self.emailTextField.delegate = self;
    self.businessTextField.delegate = self;
    self.contactTextField.delegate = self;
    // Add button properties
    [self.contactButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.contactButton setTitleColor:[Colors white] forState:UIControlStateNormal];
    [self.contactButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.contactButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
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

    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    if (self.activeTextField) {
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

#pragma mark - Action Method -

- (IBAction)contactButtonPressed:(UIStateButton *)sender {
    if ([self validateTextField:self.nameTextField text:self.nameTextField.text select:YES] &&
        [self validateTextField:self.emailTextField text:self.emailTextField.text select:YES] &&
        [self validateTextField:self.businessTextField text:self.businessTextField.text select:YES] &&
        [self validateTextField:self.contactTextField text:self.contactTextField.text select:YES] )
    {
        [PFCloud callFunctionInBackground:@"businessClaimRequest"
                           withParameters:@{@"objectId":self.objectId,
                                            @"name":self.nameTextField.text,
                                            @"email":self.emailTextField.text,
                                            @"position":self.businessTextField.text,
                                            @"contact":self.contactTextField.text}
                                    block:^(id  _Nullable object, NSError * _Nullable error)
         {
             NSString* message;

             if (error) {
                 message = NSLocalizedString(@"signup_contact_error", nil);
             } else {
                 message = NSLocalizedString(@"signup_contact_success", nil);
             }

             if (self.isViewLoaded && self.view.window) {
                 UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                                message:message
                                                                         preferredStyle:UIAlertControllerStyleAlert];
                 UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Ok"
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
                                                                [alert dismissViewControllerAnimated:YES completion:nil];
                                                                [self.navigationController popToRootViewControllerAnimated:YES];
                                                            }];
                 [alert addAction:ok];
                 [self presentViewController:alert animated:YES completion:nil];
             }
         }];
    }
}

#pragma mark - UITextFieldDelegate Methods -

- (BOOL)validateTextField:(JVFloatLabeledTextField*)textField text:(NSString*)text select:(BOOL)select {
    if (textField == self.emailTextField) {
        if (isEmailValid([self.emailTextField text])) {
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
    if (textField == self.nameTextField) {
        [self.emailTextField becomeFirstResponder];
    } else if (textField == self.emailTextField) {
        [self.businessTextField becomeFirstResponder];
    } else if (textField == self.businessTextField) {
        [self.contactTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }

    return YES;
}

#pragma mark - Navigation Method -

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
