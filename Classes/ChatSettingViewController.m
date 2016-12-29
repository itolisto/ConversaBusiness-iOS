//
//  ChatSettingViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 3/3/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "ChatSettingViewController.h"

#import "Constants.h"
#import "SettingsKeys.h"

@interface ChatSettingViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *sendSoundSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *receiveSoundSwitch;
@property (weak, nonatomic) IBOutlet UILabel *qualityImageLabel;

@end

@implementation ChatSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [self updateLabelWithQuality:[SettingsKeys getMessageImageQuality]];
    self.sendSoundSwitch.on = [SettingsKeys getMessageSoundIncoming:NO];
    self.receiveSoundSwitch.on = [SettingsKeys getMessageSoundIncoming:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([indexPath section] == 0) {
        if ([indexPath row] == 0) {
            [self selectImageQuality];
        }
    }
}

- (void)selectImageQuality {
    UIAlertController * view =   [UIAlertController
                                 alertControllerWithTitle:nil
                                 message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* High = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"settings_chat_quality_alert_action_high", nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {
                                       [SettingsKeys setMessageImageQuality:ConversaImageQualityHigh];
                                       [self updateLabelWithQuality:ConversaImageQualityHigh];
                                       [view dismissViewControllerAnimated:YES completion:nil];
                                   }];
    UIAlertAction* Medium = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"settings_chat_quality_alert_action_medium", nil)
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action) {
                                 [SettingsKeys setMessageImageQuality:ConversaImageQualityMedium];
                                 [self updateLabelWithQuality:ConversaImageQualityMedium];
                                 [view dismissViewControllerAnimated:YES completion:nil];
                             }];
    UIAlertAction* Low = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"settings_chat_quality_alert_action_low", nil)
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action) {
                                 [SettingsKeys setMessageImageQuality:ConversaImageQualityLow];
                                 [self updateLabelWithQuality:ConversaImageQualityLow];
                                 [view dismissViewControllerAnimated:YES completion:nil];
                             }];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"common_action_cancel", nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action) {
                                 [view dismissViewControllerAnimated:YES completion:nil];
                             }];
    [view addAction:High];
    [view addAction:Medium];
    [view addAction:Low];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

- (void)updateLabelWithQuality:(ConversaImageQuality)quality {
    
    switch (quality) {
        case ConversaImageQualityHigh: {
            self.qualityImageLabel.text = NSLocalizedString(@"settings_chat_quality_alert_action_high", nil);
            break;
        }
        case ConversaImageQualityMedium: {
            self.qualityImageLabel.text = NSLocalizedString(@"settings_chat_quality_alert_action_medium", nil);
            break;
        }
        case ConversaImageQualityLow: {
            self.qualityImageLabel.text = NSLocalizedString(@"settings_chat_quality_alert_action_low", nil);
            break;
        }
    }
}

- (IBAction)sendSwitchChanged:(UISwitch *)sender {
    if (sender.on) {
        [SettingsKeys setMessageSoundIncoming:NO value:YES];
    } else {
        [SettingsKeys setMessageSoundIncoming:NO value:NO];
    }
}

- (IBAction)receiveSwitchChanged:(UISwitch *)sender {
    if (sender.on) {
        [SettingsKeys setMessageSoundIncoming:YES value:YES];
    } else {
        [SettingsKeys setMessageSoundIncoming:YES value:NO];
    }
}


@end
