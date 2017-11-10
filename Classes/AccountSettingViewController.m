//
//  AccountSettingViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 12/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "AccountSettingViewController.h"

#import "AppJobs.h"
#import "Account.h"
#import "Constants.h"
#import "SettingsKeys.h"
#import "NSFileManager+Conversa.h"

@interface AccountSettingViewController ()

@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *conversaIdLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UISwitch *conversaSwitch;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

@end

@implementation AccountSettingViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];

    self.displayNameLabel.text = [SettingsKeys getDisplayName];
    NSString *conversa = [SettingsKeys getConversaId];
    if (conversa) {
        self.conversaIdLabel.text = [@"@" stringByAppendingString:conversa];
    }
    [self.conversaSwitch setOn:[SettingsKeys getRedirect] animated:YES];

    self.statusLabel.text = [self getStatusText:[SettingsKeys getStatus]];

    // Imagen redonda
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2;
    self.avatarImageView.clipsToBounds = YES;

    UIImage *image = [[NSFileManager defaultManager] loadAvatarFromLibrary:kAccountAvatarName];

    if (image) {
        self.avatarImageView.image = image;
    } else {
        self.avatarImageView.image = [UIImage imageNamed:@"ic_business_default"];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"EDQueueJobDidFail"
                                               object:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:businessDisplayName
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:businessConversaId
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:businessStatus
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:businessRedirect
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:businessAvatarUrl
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];

    [[self navigationController] setNavigationBarHidden:NO animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:businessAvatarUrl];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:businessRedirect];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:businessStatus];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:businessConversaId];
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:businessDisplayName];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)receivedNotification:(NSNotification *)notification
{
    NSDictionary *job = [notification valueForKey:@"object"];

    if ([[job objectForKey:@"task"] isEqualToString:@"redirectToConversaJob"]) {

    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (keyPath == nil || change == nil || [keyPath length] == 0 || [change count] == 0) {
        return;
    }

    if ([change valueForKey:NSKeyValueChangeNewKey] == nil || [change valueForKey:NSKeyValueChangeNewKey] == [NSNull null]) {
        return;
    }

    dispatch_sync(dispatch_get_main_queue(), ^{
        if ([keyPath isEqualToString:businessStatus]) {
            self.statusLabel.text = [self getStatusText:[[change valueForKey:NSKeyValueChangeNewKey] integerValue]];
        } else if ([keyPath isEqualToString:businessRedirect]) {
            if (self.conversaSwitch.on != [[change valueForKey:NSKeyValueChangeNewKey] boolValue]) {
                [self.conversaSwitch setOn:[[change valueForKey:NSKeyValueChangeNewKey] boolValue] animated:YES];
            }
        } else if ([keyPath isEqualToString:businessAvatarUrl]) {
            UIImage *image = [[NSFileManager defaultManager] loadAvatarFromLibrary:kAccountAvatarName];

            if (image) {
                self.avatarImageView.image = image;
            } else {
                self.avatarImageView.image = [UIImage imageNamed:@"ic_business_default"];
            }
        } else if ([keyPath isEqualToString:businessConversaId]) {
            NSString *conversaid = [SettingsKeys getConversaId];
            if (conversaid) {
                self.conversaIdLabel.text = [@"@" stringByAppendingString:conversaid];
            }
        } else if ([keyPath isEqualToString:businessDisplayName]) {
            self.displayNameLabel.text = [SettingsKeys getDisplayName];
        }
    });
}

#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath section] == 3) {
        // Log Out
        [self showLogout];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Data Methods -

- (NSString*)getStatusText:(NSInteger)status {
    switch (status) {
        case Online:
            return NSLocalizedString(@"settings_account_status_online", nil);
        case Away:
            return NSLocalizedString(@"settings_account_status_away", nil);
        case Offline:
            return NSLocalizedString(@"settings_account_status_offline", nil);
        default:
            return NSLocalizedString(@"settings_account_status_conversa", nil);
    }
}

#pragma mark - Action Methods -

- (IBAction)conversaSwitchChanged:(UISwitch *)sender {
    if (sender.on) {
        // Enable redirect
        UIAlertController * view =   [UIAlertController
                                      alertControllerWithTitle:nil
                                      message:NSLocalizedString(@"settings_account_redirect_message", nil)
                                      preferredStyle:UIAlertControllerStyleActionSheet];

        UIAlertAction* redirect = [UIAlertAction
                                   actionWithTitle:@"Ok"
                                   style:UIAlertActionStyleDestructive
                                   handler:^(UIAlertAction * action) {
                                       [sender setOn:NO animated:YES];
                                       [view dismissViewControllerAnimated:YES completion:nil];
                                   }];

        [view addAction:redirect];
        [self presentViewController:view animated:YES completion:nil];
    }
}

- (void)showLogout {
    UIAlertController * view =   [UIAlertController
                                  alertControllerWithTitle:nil
                                  message:nil
                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* logout = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"settings_account_logout_alert_action_logout", nil)
                             style:UIAlertActionStyleDestructive
                             handler:^(UIAlertAction * action) {
                                 [Account logOut];
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                 UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
                                 [self presentViewController:viewController animated:YES completion:nil];
                             }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"common_action_cancel", nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action) {
                                 [view dismissViewControllerAnimated:YES completion:nil];
                             }];
    
    
    [view addAction:logout];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

@end
