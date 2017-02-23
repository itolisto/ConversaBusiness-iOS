//
//  DetailAccountViewController.m
//  ConversaBusiness
//
//  Created by Edgar Gomez on 3/28/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "DetailAccountViewController.h"

#import "Image.h"
#import "Camera.h"
#import "Colors.h"
#import "Account.h"
#import "Constants.h"
#import "SettingsKeys.h"
#import "UIStateButton.h"
#import "MBProgressHUD.h"
#import "NSFileManager+Conversa.h"
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>

@interface DetailAccountViewController ()

@property (weak, nonatomic) IBOutlet UITextField *displayNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *conversaIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIStateButton *changeAvatarButton;

@end

@implementation DetailAccountViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];

    // Add sign up button properties
    [self.changeAvatarButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.changeAvatarButton setTitleColor:[Colors white] forState:UIControlStateNormal];
    [self.changeAvatarButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.changeAvatarButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];

    self.displayNameTextField.text = [SettingsKeys getDisplayName];
    self.conversaIdTextField.text = [SettingsKeys getConversaId];
    self.emailTextField.text = [Account currentUser].email;

    // Set delegates
    self.displayNameTextField.delegate = self;
    self.conversaIdTextField.delegate = self;
    self.passwordTextField.delegate = self;
        
    // Imagen redonda
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2;
    self.avatarImageView.clipsToBounds = YES;
    // Agregar borde
    self.avatarImageView.layer.borderWidth = 3.0f;
    self.avatarImageView.layer.borderColor = [Colors purpleNavbar].CGColor;
    
    UIImage *image = [[NSFileManager defaultManager] loadAvatarFromLibrary:kAccountAvatarName];

    if (image) {
        self.avatarImageView.image = image;
    } else {
        self.avatarImageView.image = [UIImage imageNamed:@"ic_business_default"];
    }

    // Hide keyboard when pressed outside TextField
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = FALSE;
    [self.tableView addGestureRecognizer:tap];
    tap.delegate = self;
}

- (void)dismissKeyboard {
    self.passwordTextField.text = @"";
    self.displayNameTextField.text = [SettingsKeys getDisplayName];
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate Methotd -

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    if ([textField.text length] == 0) {
        UIAlertController * view=   [UIAlertController
                                     alertControllerWithTitle:nil
                                     message:NSLocalizedString(@"settings_account_alert_change_empty_title", nil)
                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* change = [UIAlertAction
                                 actionWithTitle:@"Ok"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action) {
                                     if (textField == self.displayNameTextField) {
                                         textField.text = [SettingsKeys getDisplayName];
                                     } else if (textField == self.conversaIdTextField) {
                                         textField.text = [SettingsKeys getConversaId];
                                     }

                                     [view dismissViewControllerAnimated:YES completion:nil];
                                 }];
        [view addAction:change];
        [self presentViewController:view animated:YES completion:nil];
        return YES;
    }
    
    if (textField == self.displayNameTextField) {
        if (![textField.text isEqualToString:[SettingsKeys getDisplayName]]) {
            NSString *temp = textField.text;

            [PFCloud callFunctionInBackground:@"updateBusinessName"
                               withParameters:@{@"displayName" : temp, @"objectId": [SettingsKeys getBusinessId]}
                                        block:^(id  _Nullable object, NSError * _Nullable error)
             {
                 MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[self topViewController].view animated:YES];
                 hud.mode = MBProgressHUDModeCustomView;
                 hud.square = YES;
                 UIImage *image;

                 if (error) {
                     self.displayNameTextField.text = [SettingsKeys getDisplayName];
                     // Show notification
                     image = [[UIImage imageNamed:@"ic_warning"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                     hud.label.text = NSLocalizedString(@"settings_account_alert_displayname_not_changed", nil);
                 } else {
                     // Change displayName
                     [SettingsKeys setDisplayName:temp];
                     // Show notification
                     image = [[UIImage imageNamed:@"ic_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                     hud.label.text = NSLocalizedString(@"settings_account_alert_displayname_changed", nil);
                 }

                 hud.customView = [[UIImageView alloc] initWithImage:image];
                 [hud hideAnimated:YES afterDelay:2.f];
             }];
        }
    } else if (textField == self.conversaIdTextField) {
        if (![textField.text isEqualToString:[SettingsKeys getConversaId]]) {
            NSString *temp = textField.text;

            [PFCloud callFunctionInBackground:@"updateBusinessId"
                               withParameters:@{@"conversaID" : temp, @"objectId": [SettingsKeys getBusinessId]}
                                        block:^(id  _Nullable object, NSError * _Nullable error)
             {
                 MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[self topViewController].view animated:YES];
                 hud.mode = MBProgressHUDModeCustomView;
                 hud.square = YES;
                 UIImage *image;

                 if (error) {
                     self.conversaIdTextField.text = [SettingsKeys getConversaId];
                     // Show notification
                     image = [[UIImage imageNamed:@"ic_warning"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                     hud.label.text = NSLocalizedString(@"settings_account_alert_conversa_id_not_changed", nil);
                 } else {
                     // Change displayName
                     [SettingsKeys setConversaId:temp];
                     // Show notification
                     image = [[UIImage imageNamed:@"ic_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                     hud.label.text = NSLocalizedString(@"settings_account_alert_conversa_id_changed", nil);
                 }

                 hud.customView = [[UIImageView alloc] initWithImage:image];
                 [hud hideAnimated:YES afterDelay:2.f];
             }];
        }
    } else {
        // Password
        UIAlertController * view=   [UIAlertController
                                     alertControllerWithTitle:nil
                                     message:NSLocalizedString(@"settings_account_alert_password_title", nil)
                                     preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction* change = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"settings_account_alert_password_action_change", nil)
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action) {
                                     Account *user = [Account currentUser];
                                     user.password = self.passwordTextField.text;
                                     self.passwordTextField.text = @"";
                                     [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                         MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
                                         hud.mode = MBProgressHUDModeCustomView;
                                         hud.square = YES;
                                         UIImage *image;

                                         if (error) {
                                             // Show notification
                                             image = [[UIImage imageNamed:@"ic_warning"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                                             hud.label.text = NSLocalizedString(@"settings_account_alert_password_not_changed", nil);
                                         } else {
                                             // Show notification
                                             image = [[UIImage imageNamed:@"ic_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                                             hud.label.text = NSLocalizedString(@"settings_account_alert_password_changed", nil);
                                         }

                                         hud.customView = [[UIImageView alloc] initWithImage:image];
                                         [hud hideAnimated:YES afterDelay:2.f];
                                     }];
                                 }];
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"common_action_cancel", nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action) {
                                     self.passwordTextField.text = @"";
                                     [view dismissViewControllerAnimated:YES completion:nil];
                                 }];

        [view addAction:change];
        [view addAction:cancel];
        [[self topViewController] presentViewController:view animated:YES completion:nil];
    }

    return YES;
}

- (IBAction)avatarButtonPressed:(UIStateButton *)sender {
    UIAlertController * view=   [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* viewPhotho = [UIAlertAction
                                 actionWithTitle:@"Ver imagen"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action) {
                                     //Do some thing here
                                     NSArray *photos = [IDMPhoto photosWithImages:@[self.avatarImageView.image]];
                                     IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
                                     browser.displayActionButton = NO;
                                     browser.displayArrowButton  = NO;
                                     browser.displayCounterLabel = NO;
                                     [self presentViewController:browser animated:YES completion:nil];
                                 }];
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
    
    [view addAction:viewPhotho];
    [view addAction:photoLibrary];
    [view addAction:camera];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}


#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
                 [self processImage:UIImageJPEGRepresentation(compressImage([UIImage imageWithData:imageData], NO), 1)];
             }
         }];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)processImage:(NSData *)picture {
    if (picture) {
        PFFile *filePicture = [PFFile fileWithName:@"avatar.jpg" data:picture];
        [filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if (error == nil) {
                 self.avatarImageView.image = [UIImage imageWithData:picture];

                 [PFCloud callFunctionInBackground:@"updateBusinessAvatar"
                                    withParameters:@{@"avatar" : filePicture, @"objectId": [SettingsKeys getBusinessId]}
                                             block:^(id  _Nullable object, NSError * _Nullable error)
                  {
                      MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[self topViewController].view animated:YES];
                      hud.mode = MBProgressHUDModeCustomView;
                      hud.square = YES;
                      UIImage *image;

                      if (error) {
                          self.conversaIdTextField.text = [SettingsKeys getConversaId];
                          // Show notification
                          image = [[UIImage imageNamed:@"ic_warning"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                          hud.label.text = NSLocalizedString(@"settings_account_avatar_error_link", nil);
                      } else {
                          // Change displayName
                          // Show notification
                          image = [[UIImage imageNamed:@"ic_checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                          hud.label.text = NSLocalizedString(@"settings_account_avatar", nil);
                          // Save image
                          BOOL result = [[NSFileManager defaultManager] saveDataToLibraryDirectory:picture
                                                                                          withName:kAccountAvatarName
                                                                                      andDirectory:kMessageMediaAvatarLocation];

                          if (result) {
                              [SettingsKeys setAvatarUrl:@""];
                          }
                      }

                      hud.customView = [[UIImageView alloc] initWithImage:image];
                      [hud hideAnimated:YES afterDelay:2.f];
                  }];
             } else {
                 UIAlertController * view=   [UIAlertController
                                              alertControllerWithTitle:nil
                                              message:NSLocalizedString(@"settings_account_avatar_error", nil)
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
    }
}

#pragma mark - UIImagePickerControllerDelegate Methods -

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self processImage:UIImageJPEGRepresentation(compressImage(info[UIImagePickerControllerEditedImage], NO), 1)];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

@end
