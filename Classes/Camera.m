//
//  Camera.m
//  Conversa
//
//  Created by Edgar Gomez on 9/28/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "Camera.h"

#import "Constants.h"
#import <AVFoundation/AVFoundation.h>
#import <OHQBImagePicker/QBImagePicker.h>
#import <MobileCoreServices/MobileCoreServices.h>

void PresentPhotoCamera(id target, BOOL canEdit) {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized || status == AVAuthorizationStatusNotDetermined) {

        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            return;

        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        NSString *type = (NSString *)kUTTypeImage;

        if ([[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:type])
        {
            imagePicker.mediaTypes = @[type];
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;

            if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear])
            {
                imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
            }
            else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront])
            {
                imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            }
        }
        else return;

        imagePicker.allowsEditing = canEdit;
        imagePicker.showsCameraControls = YES;
        imagePicker.delegate = target;
        [target presentViewController:imagePicker animated:YES completion:nil];
    } else {
        UIAlertController * alert =  [UIAlertController
                                      alertControllerWithTitle:nil
                                      message:@"No tienes permiso para ver usar la cámara. Ve a ajustes para cambiar el estado."
                                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Ok"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];

        [alert addAction:ok];
        [target presentViewController:alert animated:YES completion:nil];
    }
}

void PresentPhotoLibrary(id target, BOOL canEdit, int max) {
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusAuthorized) {
        QBImagePickerController *imagePickerController = [QBImagePickerController new];
        imagePickerController.delegate = target;
        imagePickerController.allowsMultipleSelection = YES;
        imagePickerController.maximumNumberOfSelection = max;
        imagePickerController.showsNumberOfSelectedItems = YES;
        imagePickerController.mediaType = QBImagePickerMediaTypeImage;
        imagePickerController.assetCollectionSubtypes = @[
                                                          @(PHAssetCollectionSubtypeSmartAlbumUserLibrary), // Camera Roll
                                                          @(PHAssetCollectionSubtypeAlbumMyPhotoStream), // My Photo Stream
                                                          @(PHAssetCollectionSubtypeSmartAlbumPanoramas), // Panoramas
                                                          ];

        [target presentViewController:imagePickerController animated:YES completion:NULL];
    } else {
        //No permission. Trying to normally request it
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status != PHAuthorizationStatusAuthorized) {
                //User don't give us permission. Showing alert with redirection to settings
                //Getting description string from info.plist file
                NSString *accessDescription = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSPhotoLibraryUsageDescription"];
                UIAlertController * alertController = [UIAlertController alertControllerWithTitle:accessDescription message:@"To give permissions tap on 'Change Settings' button" preferredStyle:UIAlertControllerStyleAlert];

                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                [alertController addAction:cancelAction];

                UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"Change Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }];
                [alertController addAction:settingsAction];
                [target presentViewController:alertController animated:YES completion:nil];
            }
        }];
    }
}

void PresentMultiCamera(id target, BOOL canEdit) {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (status == AVAuthorizationStatusAuthorized || status == AVAuthorizationStatusNotDetermined) {
        
        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            return;

        NSString *type1 = (NSString *)kUTTypeImage;
        NSString *type2 = (NSString *)kUTTypeMovie;
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];

        if ([[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:type1])
        {
            imagePicker.mediaTypes = @[type1, type2];
            imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
            imagePicker.videoMaximumDuration = VIDEO_LENGTH;
            imagePicker.videoQuality = UIImagePickerControllerQualityType640x480;

            if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear])
            {
                imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
            }
            else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront])
            {
                imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
            }
        }
        else return;

        imagePicker.allowsEditing = canEdit;
        imagePicker.showsCameraControls = YES;
        imagePicker.delegate = target;
        [target presentViewController:imagePicker animated:YES completion:nil];
    } else {
        UIAlertController * alert =  [UIAlertController
                                      alertControllerWithTitle:nil
                                      message:@"No tienes permiso para ver usar la cámara. Ve a ajustes para cambiar el estado."
                                      preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* ok = [UIAlertAction actionWithTitle:@"Ok"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action)
                             {
                                 [alert dismissViewControllerAnimated:YES completion:nil];
                             }];
        
        [alert addAction:ok];
        [target presentViewController:alert animated:YES completion:nil];
    }
}
