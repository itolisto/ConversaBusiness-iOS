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
#import "UIStateButton.h"
#import "NSFileManager+Conversa.h"
#import "ProfileDialogViewController.h"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImage;
@property (weak, nonatomic) IBOutlet UILabel *helloLabel;
@property (weak, nonatomic) IBOutlet UIStateButton *viewButton;

@end

@implementation SettingsViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];

    // Add border to Button
    [self.viewButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.viewButton setTitleColor:[Colors white] forState:UIControlStateNormal];
    [self.viewButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.viewButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];

    // Imagen redonda
    self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.width / 2;
    self.avatarImage.clipsToBounds = YES;

    UIImage *image = [[NSFileManager defaultManager] loadAvatarFromLibrary:kAccountAvatarName];

    if (image) {
        self.avatarImage.image = image;
    } else {
        self.avatarImage.image = [UIImage imageNamed:@"ic_business_default"];
    }

    // Welcome
    self.helloLabel.text = [NSString stringWithFormat:@"%@, %@", NSLocalizedString(@"settings_home_profile_hi", nil), [SettingsKeys getDisplayName]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"EDQueueJobDidSucceed"
                                               object:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:businessDisplayName
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:businessAvatarUrl
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
}

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:businessAvatarUrl];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:businessDisplayName];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    //NSLog(@"KVO: %@ changed property %@ to value %@", object, keyPath, change);
    if (keyPath == nil || change == nil || [keyPath length] == 0 || [change count] == 0) {
        return;
    }

    if ([change valueForKey:NSKeyValueChangeNewKey] == nil) {
        return;
    }

    if ([keyPath isEqualToString:businessDisplayName]) {
        self.helloLabel.text = [NSString stringWithFormat:@"%@, %@", NSLocalizedString(@"settings_home_profile_hi", nil), [change valueForKey:NSKeyValueChangeNewKey]];
    } else if ([keyPath isEqualToString:businessAvatarUrl]) {
        UIImage *image = [[NSFileManager defaultManager] loadAvatarFromLibrary:kAccountAvatarName];
        if (image) {
            self.avatarImage.image = image;
        } else {
            self.avatarImage.image = [UIImage imageNamed:@"ic_business_default"];
        }
    }
}

#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation Method -

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"ProfileFromSettings"]) {
        return ([SettingsKeys getBusinessId] == nil || [SettingsKeys getBusinessId].length == 0) ? NO : YES;
    } else {
        return YES;
    }
}

@end
