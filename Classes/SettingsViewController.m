//
//  SettingsViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 11/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "SettingsViewController.h"

#import "Colors.h"
#import "Account.h"
#import "Utilities.h"
#import "SettingsKeys.h"
#import "NSFileManager+Conversa.h"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property (weak, nonatomic) IBOutlet UILabel *helloLabel;
@property (weak, nonatomic) IBOutlet UIButton *viewButton;

@end

@implementation SettingsViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];

    // Add border to Button
    [[self.viewButton layer] setBorderWidth:1.0f];
    [[self.viewButton layer] setBorderColor:[UIColor whiteColor].CGColor];
    [[self.viewButton layer] setCornerRadius:15.0f];

    // Imagen redonda
    self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.width / 2;
    self.avatarImage.clipsToBounds = YES;

    UIImage *image = [[NSFileManager defaultManager] loadAvatarFromLibrary:[[Account currentUser].objectId stringByAppendingString:@"_avatar.jpg"]];

    if (image) {
        self.avatarImage.image = image;
    } else {
        self.avatarImage.image = [UIImage imageNamed:@"ic_person_female"];
    }

    // Welcome
    self.helloLabel.text = [NSString stringWithFormat:@"%@, %@", NSLocalizedString(@"settings_home_profile_hi", nil), [SettingsKeys getDisplayName]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"EDQueueJobDidSucceed"
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
}

- (void)receivedNotification:(NSNotification *)notification
{
    NSDictionary *job = [notification valueForKey:@"object"];

    if ([[job objectForKey:@"task"] isEqualToString:@"downloadAvatarJob"]) {
        // Update avatar
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            UIImage *image = [[NSFileManager defaultManager] loadAvatarFromLibrary:[[Account currentUser].objectId stringByAppendingString:@"_avatar.jpg"]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (image) {
                    self.avatarImage.image = image;
                }
            });
        });
    } else if ([[job objectForKey:@"task"] isEqualToString:@"businessDataJob"]) {
        self.helloLabel.text = [NSString stringWithFormat:@"%@, %@", NSLocalizedString(@"settings_home_profile_hi", nil), [SettingsKeys getDisplayName]];
    }
}

- (IBAction)viewButtonPressed:(UIButton *)sender {

}

#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath section] == 3) {
        [self didSelectShareSetting:indexPath];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)didSelectShareSetting:(NSIndexPath*)indexPath {
    NSString *textToShare = NSLocalizedString(@"settings_home_share_text", nil);
    NSURL *myWebsite = [NSURL URLWithString:@"http://www.conversachat.com/"];
    
    NSArray *objectsToShare = @[textToShare, myWebsite];
    
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

@end
