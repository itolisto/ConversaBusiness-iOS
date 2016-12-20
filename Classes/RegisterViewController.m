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
@property (weak, nonatomic) IBOutlet UITextField *birthdayText;
@property (weak, nonatomic) IBOutlet UISegmentedControl *genderControl;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation RegisterViewController

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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];

    UIDatePicker *datePicker = [[UIDatePicker alloc] init];
    datePicker.datePickerMode = UIDatePickerModeDate;
    [datePicker setMaximumDate:[NSDate date]];
    [datePicker addTarget:self action:@selector(updateTextField:)
         forControlEvents:UIControlEventValueChanged];

    [self.birthdayText setInputView:datePicker];

    [[self.signupButton layer] setCornerRadius:borderCornerRadius];
}

- (void) dismissKeyboard {
    //Causes the view (or one of its embedded text fields) to resign the first responder status.
    [self.view endEditing:YES];
}

-(void)resignKeyboard {
    [self.birthdayText resignFirstResponder];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary *info = aNotification.userInfo;

    CGRect rawFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, 140.0, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    if ([self.birthdayText isFirstResponder]) {
        if ([self.birthdayText inputAccessoryView] == nil) {
            UIToolbar *keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, keyboardFrame.size.height, self.view.frame.size.width, 44)] ;
            [keyboardToolbar setBarStyle:UIBarStyleBlack];
            [keyboardToolbar setTranslucent:YES];
            [keyboardToolbar sizeToFit];
            UIBarButtonItem *flexButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                        target:self
                                                                                        action:nil];
            UIBarButtonItem *doneButton1 =[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"signup_birhtday_toolbar_done", nil)
                                                                           style:UIBarButtonItemStyleDone
                                                                          target:self
                                                                          action:@selector(resignKeyboard)];

            NSArray *itemsArray = [NSArray arrayWithObjects:flexButton,doneButton1, nil];
            [keyboardToolbar setItems:itemsArray];
            [self.birthdayText setInputAccessoryView:keyboardToolbar];
            [self.birthdayText reloadInputViews];
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

#pragma mark - IBAction Methods -

- (IBAction)registerButtonPressed:(UIButton *)sender {
    [self doRegister];
}

- (IBAction)backBarButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate Method -

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else {
        [self doRegister];
    }
    
    return YES;
}

#pragma mark - Register Methods -

-(void)updateTextField:(UIDatePicker *)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    self.birthdayText.text = [dateFormatter stringFromDate:sender.date];
}

- (BOOL) validForm {
    MBProgressHUD *hudError = [[MBProgressHUD alloc] initWithView:self.view];
    hudError.mode = MBProgressHUDModeText;
    [self.view addSubview:hudError];
    
    if(isEmailValid([self.emailTextField text])) {
        if([self.passwordTextField hasText]) {
            [hudError removeFromSuperview];
            return YES;
        } else {
            hudError.label.text = NSLocalizedString(@"signup_password_length_error", nil);
            [hudError showAnimated:YES];
            [hudError hideAnimated:YES afterDelay:1.7];
            [self.passwordTextField becomeFirstResponder];
        }
    } else {
        hudError.label.text = NSLocalizedString(@"sign_email_not_valid_error", nil);
        [hudError showAnimated:YES];
        [hudError hideAnimated:YES afterDelay:1.7];
        [self.emailTextField becomeFirstResponder];
    }
    
    return NO;
}

- (void) doRegister {
    if([self validForm]) {
        Account *user = [Account object];
        NSArray *emailPieces = [self.emailTextField.text componentsSeparatedByString: @"@"];
        user.username = [emailPieces objectAtIndex: 0];
        user.email = self.emailTextField.text;
        user.password = self.passwordTextField.text;
        // Extra fields
        user[kUserTypeKey] = @(1);
        
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        
        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
            [MBProgressHUD hideHUDForView:self.view animated:YES];
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

- (void) showErrorMessage {
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
