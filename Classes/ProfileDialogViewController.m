//
//  ProfileDialogViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 11/28/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "ProfileDialogViewController.h"

#import "Log.h"
#import "Colors.h"
#import "Account.h"
#import "Utilities.h"
#import "Constants.h"
#import "SettingsKeys.h"
#import "ParseValidation.h"
#import "NSFileManager+Conversa.h"

#import <SDWebImage/UIImageView+WebCache.h>

@interface ProfileDialogViewController ()

@property (assign, nonatomic, getter=isSelected) BOOL select;
@property (assign, nonatomic) NSUInteger followers;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property (weak, nonatomic) IBOutlet UIView *statusView;

@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *conversaIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *followersLabel;

@property (weak, nonatomic) IBOutlet UIImageView *headerImage;
@property (weak, nonatomic) IBOutlet UIImageView *favoriteImageView;
@property (weak, nonatomic) IBOutlet UIImageView *chatImageView;
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;

@property (strong, nonatomic) UITapGestureRecognizer* tapOutsideRecognizer;

@end

/*
 * Storyboard implementation information in 
 * http://stackoverflow.com/questions/11236367/display-clearcolor-uiviewcontroller-over-uiviewcontroller
 */

@implementation ProfileDialogViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.containerView.layer.cornerRadius = 10.0f;
    self.containerView.layer.masksToBounds = YES;

    self.avatarImage.backgroundColor = [UIColor clearColor];
    self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.width / 2;

    self.statusView.backgroundColor = [Colors profileOffline];
    self.statusView.layer.cornerRadius = self.statusView.frame.size.width / 2;
    // Agregar borde
    self.statusView.layer.borderWidth = 2.0f;
    self.statusView.layer.borderColor = [Colors white].CGColor;

    UIImage *image = [[NSFileManager defaultManager] loadAvatarFromLibrary:kAccountAvatarName];

    if (image) {
        self.avatarImage.image = image;
    } else {
        self.avatarImage.image = [UIImage imageNamed:@"ic_business_default"];
    }

    self.displayNameLabel.text = [SettingsKeys getDisplayName];
    self.conversaIdLabel.text = [@"@" stringByAppendingString:[SettingsKeys getConversaId]];

    self.select = YES;
    self.favoriteButton.enabled = NO;
    self.favoriteImageView.image = [UIImage imageNamed:@"ic_fav"];
    self.chatButton.enabled = NO;

    [PFCloud callFunctionInBackground:@"getBusinessProfile"
                       withParameters:@{@"businessId": [SettingsKeys getBusinessId], @"count": @(NO)}
                                block:^(NSString * _Nullable result, NSError * _Nullable error)
     {
         if (error) {
             if ([ParseValidation validateError:error]) {
                 [ParseValidation _handleInvalidSessionTokenError:self];
             }
         } else {
             id object = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:0
                                                           error:&error];
             if (!error) {
                 NSDictionary *results = object;

                 self.followers = 0;
                 NSString *header = nil;
                 bool favorite = NO;
                 int status = 0;

                 if ([results objectForKey:@"header"] && [results objectForKey:@"header"] != [NSNull null]) {
                     header = [results objectForKey:@"header"];
                 }

                 if ([results objectForKey:@"followers"] && [results objectForKey:@"followers"] != [NSNull null]) {
                     self.followers = [[results objectForKey:@"followers"] unsignedIntegerValue];
                 } else {
                     self.followers = 0;
                 }

                 if ([results objectForKey:@"favorite"] && [results objectForKey:@"favorite"] != [NSNull null]) {
                     favorite = [[results objectForKey:@"favorite"] boolValue];
                 }

                 if ([results objectForKey:@"status"] && [results objectForKey:@"status"] != [NSNull null]) {
                     status = [[results objectForKey:@"status"] intValue];
                 }

                 if (header != nil) {
                     [self.headerImage sd_setImageWithURL:[NSURL URLWithString:header]
                                         placeholderImage:[UIImage imageNamed:@"im_help_pattern"]];
                 }

                 // Status
                 switch (status) {
                     case 0: {
                         self.statusView.backgroundColor = [Colors profileOnline];
                         break;
                     }
                     case 1: {
                         self.statusView.backgroundColor = [Colors profileAway];
                         break;
                     }
                     default: {
                         self.statusView.backgroundColor = [Colors profileOffline];
                         break;
                     }
                 }

                 if (favorite) {
                     [self changeFavorite:YES];
                 }

                 self.followersLabel.text = numberWithFormat(self.followers);
             }
         }

         self.favoriteButton.enabled = YES;
     }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(self.tapOutsideRecognizer == nil) {
        self.tapOutsideRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(handleTapBehind:)];
        self.tapOutsideRecognizer.numberOfTapsRequired = 1;
        self.tapOutsideRecognizer.cancelsTouchesInView = false;
        self.tapOutsideRecognizer.delegate = self;
        [self.view.window addGestureRecognizer:self.tapOutsideRecognizer];
    }

    UIView* baseView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                0,
                                                                [[UIScreen mainScreen] bounds].size.width,
                                                                [[UIScreen mainScreen] bounds].size.height)];
    baseView.tag = 512;
    baseView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.45];
    baseView.alpha = 0.0;
    [self.view insertSubview:baseView atIndex:0];

    [UIView animateWithDuration:0.20 animations:^{
        baseView.alpha = 1.0;
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if(self.tapOutsideRecognizer != nil) {
        [self.view.window removeGestureRecognizer:self.tapOutsideRecognizer];
        self.tapOutsideRecognizer = nil;
    }
}

#pragma mark - Action Method -

- (void)handleTapBehind:(UITapGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [sender locationInView:self.view];

        if (!CGRectContainsPoint([self.containerView frame], location)) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (void)changeFavorite:(BOOL)favorite {
    self.select = favorite;
    CGAffineTransform expandTransform = CGAffineTransformMakeScale(1.2, 1.2);
    self.favoriteImageView.transform = expandTransform;

    if (favorite) {
        self.favoriteImageView.image = [UIImage imageNamed:@"ic_fav"];
    } else {
        self.favoriteImageView.image = [UIImage imageNamed:@"ic_fav_not"];
    }

    [UIView animateWithDuration:0.4
                          delay:0.0
         usingSpringWithDamping:0.4
          initialSpringVelocity:0.2
                        options:UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         self.favoriteImageView.transform = CGAffineTransformIdentity;
                     } completion:nil];
}

#pragma mark - UIButton Methods -

- (IBAction)favoritePressed:(UIButton *)sender {
    sender.enabled = NO;

    if ([self isSelected]) {
        [self changeFavorite:NO];
        if (self.followers > 0)
            self.followers--;
    } else {
        [self changeFavorite:YES];
        self.followers++;
    }

    if (self.followers > 999) {
        NSNumberFormatter *formatterCurrency = [[NSNumberFormatter alloc] init];

        formatterCurrency.numberStyle = NSNumberFormatterDecimalStyle;
        [formatterCurrency setMinimumFractionDigits:1];
        [formatterCurrency setMaximumFractionDigits:1];

        NSString *newString = [formatterCurrency stringFromNumber:[NSNumber numberWithFloat:(float)(self.followers/1000.0)]];

        self.followersLabel.text = [NSString stringWithFormat:@"%@K", newString];
    } else {
        self.followersLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.followers];
    }

    sender.enabled  = YES;
}

- (IBAction)sharePressed:(UIButton *)sender {
    NSString *link = [@"https://conversa.link/" stringByAppendingString:[SettingsKeys getConversaId]];

    NSString *textToShare = [NSString stringWithFormat:NSLocalizedString(@"profile_share_text", nil), [SettingsKeys getDisplayName], link];

    NSArray *objectsToShare = @[textToShare, link];

    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:objectsToShare applicationActivities:nil];

    NSArray *excludeActivities = @[UIActivityTypeAirDrop,
                                   UIActivityTypePrint,
                                   UIActivityTypeAssignToContact,
                                   UIActivityTypeSaveToCameraRoll,
                                   UIActivityTypeAddToReadingList,
                                   UIActivityTypePostToFlickr,
                                   UIActivityTypePostToVimeo];

    activityVC.excludedActivityTypes = excludeActivities;

    [self presentViewController:activityVC animated:YES completion:nil];
}

- (IBAction)closePressed:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
