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
#import "Business.h"
#import "Constants.h"
#import "YapTag.h"
#import "NSFileManager+Conversa.h"

#import "YapTag.h"

@interface DetailAccountViewController ()
@property (weak, nonatomic) IBOutlet UITextField *displayNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *conversaIdTextField;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@end

@implementation DetailAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set delegates
    self.displayNameTextField.delegate = self;
    self.conversaIdTextField.delegate  = self;
        
    // Imagen redonda
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2;
    self.avatarImageView.clipsToBounds = YES;
    // Agregar borde
    self.avatarImageView.layer.borderWidth = 3.0f;
    self.avatarImageView.layer.borderColor = [Colors greenColor].CGColor;
    
    if (self.avatar) {
        self.avatarImageView.image = self.avatar;
    } else {
        self.avatarImageView.image = [UIImage imageNamed:@"person"];
    }
    
    [YapTag deleteAllTags];
}

#pragma mark - UITextFieldDelegate Methotd -

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (textField == self.displayNameTextField) {
//        Account *user = [Account currentUser];
//        user.password = self.passwordTextField.text;
//        
//        MBProgressHUD *hudError = [[MBProgressHUD alloc] initWithView:self.view];
//        hudError.mode = MBProgressHUDModeText;
//        [self.view addSubview:hudError];
//        
//        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
//            if (succeeded && !error) {
//                hudError.labelText = @"Contraseña cambiada";
//                [hudError show:YES];
//                [hudError hide:YES afterDelay:1.7];
//            } else {
//                hudError.labelText = @"Contraseña no se ha cambiado";
//                [hudError show:YES];
//                [hudError hide:YES afterDelay:1.7];
//            }
//            self.passwordTextField.text = @"";
//        }];
    }
    
    return YES;
}

- (IBAction)avatarButtonPressed:(UIButton *)sender {
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

#pragma mark - UIImagePickerControllerDelegate Method -

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = compressImage(info[UIImagePickerControllerEditedImage], NO);
    
    if (image) {
        [self processImage:UIImageJPEGRepresentation(image, 0.5)];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)image:(UIImage *)image finishedSavingWithError:(NSError *) error contextInfo:(void *)contextInfo {
    if (error) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: @"Error"
                              message: @"Hubo un error al guardar la imagen"
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
    }
}

//- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingItems:(NSArray *)items
//{
//    for (PHAsset *asset in items) {
//        PHImageManager *manager = [PHImageManager defaultManager];
//        [manager requestImageDataForAsset:asset
//                                  options:nil
//                            resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info)
//         {
//             if (imageData) {
//                 [self processImage:UIImageJPEGRepresentation(compressImage([UIImage imageWithData:imageData], NO), 1)];
//             }
//         }];
//    }
//    
//    [self dismissViewControllerAnimated:YES completion:NULL];
//}
//
//- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
//    [self dismissViewControllerAnimated:YES completion:NULL];
//}

- (void)processImage:(NSData *)picture {
    if (picture) {
        PFFile *filePicture = [PFFile fileWithName:@"avatar.jpg" data:picture];
        [filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if (error != nil) {
                 UIAlertController * view=   [UIAlertController
                                              alertControllerWithTitle:nil
                                              message:nil
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
                 self.avatarImageView.image = [UIImage imageWithData:picture];
                 Account *account = [Account currentUser];
                 account[kUserAvatarKey] = filePicture;
                 [account saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                     if (!succeeded || error) {
                         [account saveEventually];
                     }
                 }];
                 // Save to Cache Directory
                 [[NSFileManager defaultManager] saveDataToCachesDirectory:picture
                                                                  withName:kAccountAvatarName
                                                              andDirectory:kMessageMediaImageLocation];
             }
         }];
    }
}

@end
