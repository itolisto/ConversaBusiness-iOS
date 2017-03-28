//
//  RegisterCompleteViewController.h
//  ConversaManager
//
//  Created by Edgar Gomez on 12/27/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

@import UIKit;
#import <SafariServices/SafariServices.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

@interface RegisterCompleteViewController : UIViewController <TTTAttributedLabelDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, SFSafariViewControllerDelegate>

//@property(strong, nullable, nonatomic) UIImage *avatar;
@property(strong, nonnull, nonatomic) NSString *businessName;
@property(strong, nonnull, nonatomic) NSString *conversaId;
@property(strong, nonnull, nonatomic) NSString *categoryId;
@property(strong, nonnull, nonatomic) NSString *localIdentifier;

@end
