//
//  RecoverViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 1/18/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "RecoverViewController.h"

#import "Colors.h"
#import "Utilities.h"
#import "Constants.h"
#import "UIStateButton.h"
#import "MBProgressHUD.h"
#import "JVFloatLabeledTextField.h"

#import <Parse/Parse.h>

@interface RecoverViewController ()

@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *emailTextField;
@property (weak, nonatomic) IBOutlet UIStateButton *sendPasswordButton;

@end

@implementation RecoverViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    self.emailTextField.delegate = self;
    // Hide keyboard when pressed outside TextField
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    tap.delegate = self;
    // Add login button properties
    [self.sendPasswordButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.sendPasswordButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendPasswordButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.sendPasswordButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
}

#pragma mark - UITextFieldDelegate Method -

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Observer Method -

- (void) dismissKeyboard {
    //Causes the view (or one of its embedded text fields) to resign the first responder status.
    [self.view endEditing:YES];
}

#pragma mark - Action Method -

- (IBAction)recoverButtonPressed:(UIButton *)sender {
    if (isEmailValid(self.emailTextField.text)) {
        [PFUser requestPasswordResetForEmailInBackground:self.emailTextField.text block:^(BOOL succeeded, NSError * _Nullable error) {
            if (error) {
                UIAlertController* view = [UIAlertController
                                           alertControllerWithTitle:nil
                                           message:NSLocalizedString(@"recover_password_failed_message", nil)
                                           preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction* ok = [UIAlertAction
                                     actionWithTitle:@"Ok"
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * action) {
                                         [view dismissViewControllerAnimated:YES completion:nil];
                                     }];
                
                [view addAction:ok];
                [self presentViewController:view animated:YES completion:nil];
            } else {
                UIAlertController* view = [UIAlertController
                                           alertControllerWithTitle:nil
                                           message:NSLocalizedString(@"recover_password_sent_message", nil)
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
        }];
    } else {
        UIAlertController* view = [UIAlertController
                                   alertControllerWithTitle:nil
                                   message:NSLocalizedString(@"sign_email_not_valid_error", nil)
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
}

#pragma mark - Navigation Method -

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
