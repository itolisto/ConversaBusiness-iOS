//
//  NotificationsViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 2/28/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "NotificationsViewController.h"

#import "SettingsKeys.h"

@interface NotificationsViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *backgroundSoundSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *backgroundPreviewMessageSwitch;

@property (weak, nonatomic) IBOutlet UISwitch *inAppSoundSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *previewMessageSwitch;



@end

@implementation NotificationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.backgroundSoundSwitch.on = [SettingsKeys getNotificationSoundInApp:NO];
    self.backgroundPreviewMessageSwitch.on = [SettingsKeys getNotificationPreviewInApp:NO];
    self.inAppSoundSwitch.on = [SettingsKeys getNotificationSoundInApp:YES];
    self.previewMessageSwitch.on = [SettingsKeys getNotificationPreviewInApp:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (IBAction)inAppSoundChanged:(UISwitch *)sender {
    if (sender.on) {
        [SettingsKeys setNotificationSound:YES inApp:YES];
    } else {
        [SettingsKeys setNotificationSound:NO inApp:YES];
    }
}

- (IBAction)previewMessageChanged:(UISwitch *)sender {
    if (sender.on) {
        [SettingsKeys setNotificationPreview:YES inApp:YES];
    } else {
        [SettingsKeys setNotificationPreview:NO inApp:YES];
    }
}

- (IBAction)backgroundSoundChanged:(UISwitch *)sender {
    if (sender.on) {
        [SettingsKeys setNotificationSound:YES inApp:NO];
    } else {
        [SettingsKeys setNotificationSound:NO inApp:NO];
    }
}

- (IBAction)backgroundPreviewMessageChanged:(UISwitch *)sender {
    if (sender.on) {
        [SettingsKeys setNotificationPreview:YES inApp:NO];
    } else {
        [SettingsKeys setNotificationPreview:NO inApp:NO];
    }
}


@end
