//
//  DetailAccountViewController.h
//  ConversaBusiness
//
//  Created by Edgar Gomez on 3/28/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import UIKit;
//#import <OHQBImagePicker/QBImagePicker.h>
#import <IDMPhotoBrowser/IDMPhotoBrowser.h>

@interface DetailAccountViewController : UITableViewController <UITextFieldDelegate, UIImagePickerControllerDelegate>
//QBImagePickerControllerDelegate

@property(weak, nonatomic)UIImage *avatar;

@end
