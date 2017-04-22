//
//  CheckViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/25/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "CheckViewController.h"

#import "Colors.h"
#import "nBusiness.h"
#import "UIStateButton.h"
#import "MBProgressHUD.h"
#import "JVFloatLabeledTextField.h"
#import "BusinessListViewController.h"
#import <Parse/Parse.h>

@interface CheckViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *nameTextField;
@property (weak, nonatomic) IBOutlet UIStateButton *checkButton;
@property (weak, nonatomic) IBOutlet UIStateButton *skipButton;

@property (strong, nonatomic) NSMutableArray<nBusiness *> *businessList;

@end

@implementation CheckViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    // Hide keyboard when pressed outside TextField
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    tap.delegate = self;
    // Add delegates
    self.nameTextField.delegate = self;
    // Add login button properties
    [self.checkButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.checkButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.checkButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.checkButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];

    [self.skipButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateNormal];
    [self.skipButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.skipButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.skipButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
    // Init array
    self.businessList = [NSMutableArray new];
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

- (void)dealloc {
    [self.businessList removeAllObjects];
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
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.nameTextField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.nameTextField.frame animated:YES];
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

- (IBAction)checkButtonPressed:(UIStateButton *)sender {
    if ([self validateTextField:self.nameTextField text:self.nameTextField.text select:YES]) {
        [self performSearch];
    }
}

- (void)performSearch {
    [PFCloud callFunctionInBackground:@"businessClaimSearch"
                       withParameters:@{@"search": self.nameTextField.text}
                                block:^(NSString*  _Nullable json, NSError * _Nullable error)
     {
         if (error) {

         } else {
             NSData *objectData = [json dataUsingEncoding:NSUTF8StringEncoding];
             NSArray *results = [NSJSONSerialization JSONObjectWithData:objectData
                                                                options:NSJSONReadingMutableContainers
                                                                  error:&error];

             if (error) {

             } else {
                 NSUInteger size = [results count];

                 for (int i = 0; i < size; i++) {
                     NSDictionary *object = [results objectAtIndex:i];
                     nBusiness *business = [[nBusiness alloc] init];
                     business.objectId = [object objectForKey:@"oj"];
                     business.displayName = [object objectForKey:@"dn"];
                     business.conversaId = [object objectForKey:@"id"];
                     business.avatarUrl = [object objectForKey:@"av"];
                     [self.businessList addObject:business];
                 }

                 if (size > 0) {
                     // Perform empty segue
                     [self performSegueWithIdentifier:@"businessListSegue" sender:nil];
                 } else {
                     // Perform business list segue
                     [self performSegueWithIdentifier:@"businessEmptySegue" sender:nil];
                 }
             }
         }
     }];
}

#pragma mark - UITextFieldDelegate Methods -

- (BOOL)validateTextField:(JVFloatLabeledTextField*)textField text:(NSString*)text select:(BOOL)select {
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Navigation Method -

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"businessListSegue"]) {
        BusinessListViewController *destination = [segue destinationViewController];
        destination.businessList = [self.businessList copy];
        [self.businessList removeAllObjects];
    }
}

@end
