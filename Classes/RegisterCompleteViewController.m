//
//  RegisterCompleteViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/27/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "RegisterCompleteViewController.h"

#import "Colors.h"
#import "Account.h"
#import "nCountry.h"
#import "Utilities.h"
#import "Constants.h"
#import "LoginHandler.h"
#import "UIStateButton.h"
#import "MBProgressHUD.h"
#import "JVFloatLabeledTextField.h"
#import <Photos/Photos.h>

@interface RegisterCompleteViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *emailTextField;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *passwordTextField;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *countryTextField;
@property (weak, nonatomic) IBOutlet UIStateButton *registerButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *termsPrivacyLabel;

@property (strong, nonatomic) nCountry *countryPicked;
@property (weak, nonatomic) UITextField *activeTextField;
@property (strong, nonatomic) UIPickerView *countryPickerView;
@property (strong, nonatomic) NSMutableArray <nCountry*> *countryData;

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
    // Set category input view
    self.countryData = [NSMutableArray arrayWithCapacity:30];
    self.countryPickerView = [[UIPickerView alloc] init];

    [self.countryPickerView setDataSource: self];
    [self.countryPickerView setDelegate: self];
    self.countryPickerView.showsSelectionIndicator = YES;
    self.countryTextField.inputView = self.countryPickerView;

    NSMutableAttributedString* attrStr = [[NSMutableAttributedString alloc] initWithString:self.termsPrivacyLabel.text
                                                                                attributes:nil];

    NSString *language = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2];
    NSRange start, startPrivacy;

    if ([language isEqualToString:@"es"]) {
        start = [self.termsPrivacyLabel.text rangeOfString:@"TERMINOS"];
        startPrivacy = NSMakeRange([self.termsPrivacyLabel.text rangeOfString:@"POLITICAS"].location, 23);
    } else {
        start = [self.termsPrivacyLabel.text rangeOfString:@"TERMS"];
        startPrivacy = NSMakeRange([self.termsPrivacyLabel.text rangeOfString:@"PRIVACY"].location, 16);
    }

    // Rest of Text normal
    [attrStr setAttributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}
                     range:NSMakeRange(0, start.location)];
    // Only "Y" (es) or "AND" (en) need a range because is in the middle
    [attrStr setAttributes:@{NSForegroundColorAttributeName:[UIColor lightGrayColor]}
                     range:NSMakeRange(start.location + start.length, ([language isEqualToString:@"es"]) ? 3 : 5)];
    // Green
    [attrStr setAttributes:@{NSForegroundColorAttributeName:[Colors green]}
                     range:start];
    [attrStr setAttributes:@{NSForegroundColorAttributeName:[Colors green]}
                     range:startPrivacy];

    self.termsPrivacyLabel.activeLinkAttributes = @{NSForegroundColorAttributeName:[UIColor lightGrayColor]};
    self.termsPrivacyLabel.linkAttributes = @{NSForegroundColorAttributeName: [Colors purple],
                                              NSUnderlineStyleAttributeName: [NSNumber numberWithBool:NO]
                                              };

    NSURL *url = [NSURL URLWithString:@"http://manager.conversachat.com/terms"];
    NSURL *urlPrivacy = [NSURL URLWithString:@"http://manager.conversachat.com/privacy"];

    self.termsPrivacyLabel.attributedText = attrStr;

    [self.termsPrivacyLabel addLinkToURL:url withRange:start];
    [self.termsPrivacyLabel addLinkToURL:urlPrivacy withRange:startPrivacy];

    self.termsPrivacyLabel.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.termsPrivacyLabel.delegate = self;

    [PFCloud callFunctionInBackground:@"getCountries"
                       withParameters:@{}
                                block:^(NSString * _Nullable json, NSError * _Nullable error)
     {
         if (self.isViewLoaded && self.view.window) {
             if (error) {
                 [self showErrorMessage:NSLocalizedString(@"signup_register_countries_error", nil)];
             } else {
                 NSArray *array = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                                                  options:0
                                                                    error:&error];
                 if (error) {
                     [self showErrorMessage:NSLocalizedString(@"signup_register_countries_error", nil)];
                 } else {
                     __block NSMutableArray *sortedCountries = [NSMutableArray arrayWithCapacity:[array count]];

                     [array enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                         nCountry *category = [[nCountry alloc] init];
                         category.objectId = [obj objectForKey:@"id"];
                         category.name = [obj objectForKey:@"na"];
                         [sortedCountries addObject:category];
                     }];

                     [sortedCountries sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                         NSString *first = [(nCountry*)obj1 getName];
                         NSString *second = [(nCountry*)obj2 getName];
                         return [first compare:second];
                     }];

                     [self.countryData addObjectsFromArray:sortedCountries];
                     [self.countryPickerView reloadAllComponents];
                 }
             }
         }
     }];
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

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    SFSafariViewController *svc = [[SFSafariViewController alloc]initWithURL:url
                                                     entersReaderIfAvailable:NO];
    svc.delegate = self;
    [self presentViewController:svc animated:YES completion:nil];
}

#pragma mark - UIGestureRecognizerDelegate Method -

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return ![touch.view isKindOfClass:[TTTAttributedLabel class]];
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

    if ([self.countryTextField isFirstResponder]) {
        if ([self.countryTextField inputAccessoryView] == nil) {
            UIToolbar *keyboardToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, kbSize.height, self.view.frame.size.width, 44)] ;
            [keyboardToolbar setBarStyle:UIBarStyleBlack];
            [keyboardToolbar setTranslucent:YES];
            [keyboardToolbar sizeToFit];
            UIBarButtonItem *flexButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                        target:self
                                                                                        action:nil];
            UIBarButtonItem *doneButton1 =[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"common_action_done", nil)
                                                                           style:UIBarButtonItemStyleDone
                                                                          target:self
                                                                          action:@selector(resignKeyboard)];

            NSArray *itemsArray = [NSArray arrayWithObjects:flexButton,doneButton1, nil];
            [keyboardToolbar setItems:itemsArray];
            [self.countryTextField setInputAccessoryView:keyboardToolbar];
            [self.countryTextField reloadInputViews];
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

- (void) dismissKeyboard {
    //Causes the view (or one of its embedded text fields) to resign the first responder status.
    [self.view endEditing:YES];
}

-(void)resignKeyboard {
    [self.countryTextField resignFirstResponder];
}

#pragma mark - Action Methods -

- (void)showErrorMessage:(NSString*)message {
    MBProgressHUD *hudError = [[MBProgressHUD alloc] initWithView:self.view];
    hudError.mode = MBProgressHUDModeText;
    [self.view addSubview:hudError];
    hudError.label.text = message;
    [hudError showAnimated:YES];
    [hudError hideAnimated:YES afterDelay:1.7];
}

- (IBAction)backButtonPressed:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)registerButtonPressed:(UIStateButton *)sender {
    if ([self validateTextField:self.emailTextField text:self.emailTextField.text select:YES] &&
        [self validateTextField:self.passwordTextField text:self.passwordTextField.text select:YES] &&
        [self validateTextField:self.countryTextField text:self.countryTextField.text select:YES])
    {
        [self doRegister];
    }
}

#pragma mark - UIPickerViewDataSource Methods -

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.countryData count];
}

#pragma mark - UIPickerViewDelegate Methods -

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[self.countryData objectAtIndex:row] getName];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.countryPicked = [self.countryData objectAtIndex:row];
    self.countryTextField.text = [self.countryPicked getName];
}

#pragma mark - UITextFieldDelegate Method -

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
            if (textField == self.countryTextField) {
                if (self.countryPicked) {
                    return YES;
                } else {
                    MBProgressHUD *hudError = [[MBProgressHUD alloc] initWithView:self.view];
                    hudError.mode = MBProgressHUDModeText;
                    [self.view addSubview:hudError];
                    hudError.label.text = NSLocalizedString(@"common_field_invalid", nil);
                    [hudError showAnimated:YES];
                    [hudError hideAnimated:YES afterDelay:1.7];
                    [textField becomeFirstResponder];
                    return NO;
                }
            } else {
                return YES;
            }
        }
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.activeTextField = nil;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailTextField) {
        [self.passwordTextField becomeFirstResponder];
    } else if (textField == self.passwordTextField) {
        [self.countryTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }

    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.countryTextField) {
        return ([string length] <= 1 ) ? NO : YES;
    } else {
        return YES;
    }
}

#pragma mark - Register Methods -

- (void)doRegister {
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    if (self.localIdentifier) {
        __block PHAsset *assetR;
        PHFetchResult *savedAssets = [PHAsset fetchAssetsWithLocalIdentifiers:@[self.localIdentifier] options:nil];
        [savedAssets enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            assetR = asset;
        }];
        PHImageManager *manager = [PHImageManager defaultManager];
        [manager requestImageDataForAsset:assetR
                                  options:PHImageRequestOptionsVersionCurrent
                            resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info)
         {
             if (imageData) {
                 PFFile *filePicture = [PFFile fileWithName:@"avatar.jpg"
                                                       data:UIImageJPEGRepresentation([UIImage imageWithData:imageData], 0.5)];

                 [filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                     if (error) {
                         [self showErrorMessage:NSLocalizedString(@"signup_complete_error", nil)];
                     } else {
                         [self completeRegister:filePicture];
                     }
                 }];
             } else {
                 [self completeRegister:nil];
             }
         }];
    } else {
        [self completeRegister:nil];
    }
}

- (void)completeRegister:(PFFile*)file {
    Account *user = [Account object];
    NSArray *emailPieces = [self.emailTextField.text componentsSeparatedByString: @"@"];
    user.username = [emailPieces objectAtIndex: 0];
    user.email = self.emailTextField.text;
    user.password = self.passwordTextField.text;
    // Extra fields
    user[kUserTypeKey] = @(2);
    user[@"displayName"] = self.businessName;
    user[@"conversaID"] = self.conversaId;
    user[@"categoryId"] = self.categoryId;
    user[@"countryId"] = [self.countryPicked getObjectId];

    if (file) {
        user[kUserTypeBusinessAvatar] = file;
    }

    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        if (error) {
            if (error.code == kPFErrorUserEmailTaken) {
                [self showErrorMessage:NSLocalizedString(@"signup_email_error", nil)];
            } else {
                [self showErrorMessage:NSLocalizedString(@"signup_complete_error", nil)];
            }
        } else {
            [LoginHandler proccessLoginForAccount:[Account currentUser] fromViewController:self];
        }
    }];
}

@end
