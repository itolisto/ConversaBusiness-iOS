//
//  RegisterViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 11/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "RegisterViewController.h"

#import "Log.h"
#import "Image.h"
#import "Colors.h"
#import "Camera.h"
#import "Account.h"
#import "Customer.h"
#import "Constants.h"
#import "Utilities.h"
#import "nCategory.h"
#import "LoginHandler.h"
#import "UIStateButton.h"
#import "MBProgressHUD.h"
#import "JVFloatLabeledTextField.h"
#import "RegisterCompleteViewController.h"
#import <Parse/Parse.h>

@interface RegisterViewController () <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *nameTextField;//Busines name
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *idTextField;//Conversa Id
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *categoryTextField;
@property (weak, nonatomic) IBOutlet UIStateButton *continueButton;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (assign, nonatomic) BOOL originalImage;
@property (strong, nonatomic) nCategory *categoryPicked;
@property (weak, nonatomic) UITextField *activeTextField;
@property (strong, nonatomic) UIPickerView *categoryPickerView;
@property (strong, nonatomic) NSMutableArray <nCategory*> *categoryData;

@end

@implementation RegisterViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    self.originalImage = YES;
    // Hide keyboard when pressed outside TextField
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    tap.delegate = self;
    // Add delegates
    self.nameTextField.delegate = self;
    self.idTextField.delegate = self;
    self.categoryTextField.delegate = self;
    // Add button properties
    [self.continueButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.continueButton setTitleColor:[Colors white] forState:UIControlStateNormal];
    [self.continueButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.continueButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
    // Rounded view
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2;
    self.avatarImageView.clipsToBounds = YES;
    // Set category input view
    self.categoryData = [NSMutableArray arrayWithCapacity:30];
    self.categoryPickerView = [[UIPickerView alloc] init];

    [self.categoryPickerView setDataSource: self];
    [self.categoryPickerView setDelegate: self];
    self.categoryPickerView.showsSelectionIndicator = YES;
    self.categoryTextField.inputView = self.categoryPickerView;

    NSString *language = [[[NSLocale preferredLanguages] objectAtIndex:0] substringToIndex:2];

    if (![language isEqualToString:@"es"] && ![language isEqualToString:@"en"]) {
        language = @"en"; // Set to default language
    }

    [PFCloud callFunctionInBackground:@"getCategories"
                       withParameters:@{@"language":language, @"no": @(0)}
                                block:^(NSString * _Nullable json, NSError * _Nullable error)
    {
        if (self.isViewLoaded && self.view.window) {
            if (error) {
                [self showErrorMessage:NSLocalizedString(@"signup_register_categories_error", nil)];
            } else {
                id object = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                                            options:0
                                                              error:&error];
                if (error) {
                    [self showErrorMessage:NSLocalizedString(@"signup_register_categories_error", nil)];
                } else {
                    NSDictionary *results = object;

                    NSArray *unsortedIds;
                    __block NSMutableArray *sortedCategory = [NSMutableArray arrayWithCapacity:30];

                    if ([results objectForKey:@"ids"] && [results objectForKey:@"ids"] != [NSNull null]) {
                        unsortedIds = [results objectForKey:@"ids"];
                    }

                    [unsortedIds enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        nCategory *category = [[nCategory alloc] init];
                        category.objectId = [obj objectForKey:@"id"];
                        category.name = [obj objectForKey:@"na"];
                        [sortedCategory addObject:category];
                    }];

                    [sortedCategory sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                        NSString *first = [(nCategory*)obj1 getName];
                        NSString *second = [(nCategory*)obj2 getName];
                        return [first compare:second];
                    }];

                    [self.categoryData addObjectsFromArray:sortedCategory];
                    [self.categoryPickerView reloadAllComponents];
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

    if ([self.categoryTextField isFirstResponder]) {
        if ([self.categoryTextField inputAccessoryView] == nil) {
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
            [self.categoryTextField setInputAccessoryView:keyboardToolbar];
            [self.categoryTextField reloadInputViews];
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
    //Causes the view (or one of its embedded text fields) to resign the first responder status.
    [self.view endEditing:YES];
}

-(void)resignKeyboard {
    [self.categoryTextField resignFirstResponder];
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

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)imageButtonPressed:(UIButton *)sender {
    PresentPhotoLibrary(self, YES, 1);
}

#pragma mark - UIPickerViewDataSource Methods -

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.categoryData count];
}

#pragma mark - UIPickerViewDelegate Methods -

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[self.categoryData objectAtIndex:row] getName];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.categoryPicked = [self.categoryData objectAtIndex:row];
    self.categoryTextField.text = [self.categoryPicked getName];
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
        if (textField == self.categoryTextField) {
            if (self.categoryPicked) {
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

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.activeTextField = nil;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.nameTextField) {
        [self.idTextField becomeFirstResponder];
    } else if (textField == self.idTextField) {
         [self.categoryTextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.categoryTextField) {
        return ([string length] <= 1 ) ? NO : YES;
    } else {
        return YES;
    }
}

#pragma mark - QBImagePickerControllerDelegate Methods -

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingItems:(NSArray *)items
{
    for (PHAsset *asset in items) {
        PHImageManager *manager = [PHImageManager defaultManager];
        [manager requestImageDataForAsset:asset
                                  options:nil
                            resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info)
         {
             if (imageData) {
                 self.avatarImageView.image = compressImage([UIImage imageWithData:imageData], NO);
                 self.originalImage = NO;
             }
         }];
    }

    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Navigation Methods -

- (BOOL)validateFields {
    return ([self validateTextField:self.nameTextField text:self.nameTextField.text select:YES] &&
            [self validateTextField:self.idTextField text:self.idTextField.text select:YES] &&
            [self validateTextField:self.categoryTextField text:self.categoryTextField.text select:YES]);
}

- (IBAction)continueButtonPressed:(UIButton*)sender {
    if ([self validateFields]) {
        MBProgressHUD *hudError = [[MBProgressHUD alloc] initWithView:self.view];
        hudError.mode = MBProgressHUDModeText;
        [self.view addSubview:hudError];
        hudError.label.text = NSLocalizedString(@"signup_checking_conversa_id", nil);
        [hudError showAnimated:YES];

        [PFCloud callFunctionInBackground:@"businessValidateId"
                           withParameters:@{@"conversaID":self.idTextField.text}
                                    block:^(id  _Nullable object, NSError * _Nullable error)
        {
            [hudError hideAnimated:YES];

            if(error) {
                MBProgressHUD *hudError = [[MBProgressHUD alloc] initWithView:self.view];
                hudError.mode = MBProgressHUDModeText;
                [self.view addSubview:hudError];
                hudError.label.numberOfLines = 0;
                hudError.label.text = NSLocalizedString(@"signup_conversaid_error", nil);
                [hudError showAnimated:YES];
                [hudError hideAnimated:YES afterDelay:2.5];
                [self.idTextField becomeFirstResponder];
                [self.idTextField setFloatingLabelTextColor:[UIColor redColor]];
                [self.idTextField setFloatingLabelActiveTextColor:[UIColor redColor]];
            } else {
                [self.idTextField setFloatingLabelTextColor:[UIColor lightGrayColor]];
                [self.idTextField setFloatingLabelActiveTextColor:[UIColor lightGrayColor]];
                [self performSegueWithIdentifier:@"continueSignupSegue" sender:nil];
            }
        }];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"continueSignupSegue"]) {
        RegisterCompleteViewController *destination = [segue destinationViewController];
        if (self.originalImage) {
            destination.avatar = nil;
        } else {
            destination.avatar = self.avatarImageView.image;
        }
        destination.businessName = self.nameTextField.text;
        destination.conversaId = self.idTextField.text;
        destination.categoryId = [self.categoryPicked getObjectId];
    }
}

@end
