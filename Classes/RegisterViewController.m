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
#import "LoginHandler.h"
#import "UIStateButton.h"
#import "MBProgressHUD.h"
#import "JVFloatLabeledTextField.h"
#import "RegisterCompleteViewController.h"

@interface RegisterViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *nameTextField;//Busines name
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *idTextField;//Conversa Id
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *categoryTextField;
@property (weak, nonatomic) IBOutlet UIStateButton *continueButton;
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
    self.nameTextField.delegate = self;
    self.idTextField.delegate = self;
    // Add button properties
    [self.continueButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.continueButton setTitleColor:[Colors white] forState:UIControlStateNormal];
    [self.continueButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.continueButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
    // Rounded view
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2;
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

-(void)resignKeyboard {
    [self.categoryTextField resignFirstResponder];
}

#pragma mark - Action Methods -

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)imageButtonPressed:(UIButton *)sender {
    UIAlertController * view=   [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* photoLibrary = [UIAlertAction
                                   actionWithTitle:@"Librería"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       //Do some thing here
                                       PresentPhotoLibrary(self, YES, 1);
                                       [view dismissViewControllerAnimated:YES completion:nil];
                                   }];
    UIAlertAction* camera = [UIAlertAction
                             actionWithTitle:@"Cámara"
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action) {
                                 //Do some thing here
                                 PresentPhotoCamera(self, YES);
                                 [view dismissViewControllerAnimated:YES completion:nil];
                             }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancelar"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action) {
                                 [view dismissViewControllerAnimated:YES completion:nil];
                             }];
    [view addAction:photoLibrary];
    [view addAction:camera];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate Method -

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (textField == self.nameTextField) {
        [self.idTextField becomeFirstResponder];
    } else if (textField == self.idTextField) {
         [self.categoryTextField becomeFirstResponder];
    } else {
        [self performSegueWithIdentifier:@"continueSignupSegue"
                                  sender:textField];
    }
    
    return YES;
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
             }
         }];
    }

    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UIImagePickerControllerDelegate Methods -

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    self.avatarImageView.image = compressImage(info[UIImagePickerControllerEditedImage], NO);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Navigation Methods -

- (BOOL)validateFields {
    return YES;
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"continueSignupSegue"]) {
        // Validate fields
        return [self validateFields];
    }

    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"continueSignupSegue"]) {
        RegisterCompleteViewController *destination = [segue destinationViewController];
        destination.avatar = self.avatarImageView.image;
    }
}

@end
