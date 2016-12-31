//
//  StatusSettingViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/21/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "StatusSettingViewController.h"

#import "Colors.h"
#import "AppJobs.h"
#import "SettingsKeys.h"

@interface StatusSettingViewController ()

@property (weak, nonatomic) IBOutlet UIView *onlineView;
@property (weak, nonatomic) IBOutlet UIView *awayView;
@property (weak, nonatomic) IBOutlet UIView *offlineView;
@property (weak, nonatomic) IBOutlet UIView *conversaView;
@property (nonatomic, assign) BusinessStatus originalStatus;
@property (nonatomic, assign) BusinessStatus status;

@end

@implementation StatusSettingViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];

    // View background
    self.onlineView.backgroundColor = [Colors profileOnline];
    self.awayView.backgroundColor = [Colors profileAway];
    self.offlineView.backgroundColor = [Colors profileOffline];
    self.conversaView.backgroundColor = [Colors green];
    
    // View redonda
    self.onlineView.layer.cornerRadius = self.onlineView.frame.size.width / 2;
    self.awayView.layer.cornerRadius = self.awayView.frame.size.width / 2;
    self.offlineView.layer.cornerRadius = self.offlineView.frame.size.width / 2;
    self.conversaView.layer.cornerRadius = self.conversaView.frame.size.width / 2;

    if ([SettingsKeys getRedirect]) {
        [self.tableView setAllowsSelection:NO];
    }

    self.originalStatus = [SettingsKeys getStatus];
    self.status = self.originalStatus;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"EDQueueJobDidFail"
                                               object:nil];
    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:businessStatus
                                               options:NSKeyValueObservingOptionNew
                                               context:NULL];
}

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:businessStatus];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)receivedNotification:(NSNotification *)notification
{
    NSDictionary *job = [notification valueForKey:@"object"];

    if ([[job objectForKey:@"task"] isEqualToString:@"statusChangeJob"]) {
        NSDictionary *data = [job objectForKey:@"data"];
        NSInteger old = [[data objectForKey:@"old"] integerValue];

        if (self.tableView != nil) {
            self.originalStatus = old;
            self.status = old;
            [self.tableView reloadData];
        }

        UIViewController *presenting = [self topViewController];

        if (presenting != nil && presenting.presentedViewController == nil) {
            // Enable redirect
            UIAlertController * view =   [UIAlertController
                                          alertControllerWithTitle:nil
                                          message:NSLocalizedString(@"settings_account_status_message_fail", nil)
                                          preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction* ok = [UIAlertAction
                                 actionWithTitle:@"Ok"
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action) {
                                     [view dismissViewControllerAnimated:YES completion:nil];
                                 }];
            [view addAction:ok];
            [presenting presentViewController:view animated:YES completion:nil];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"KVO: %@ changed property %@ to value %@", object, keyPath, change);
    if (keyPath == nil || change == nil || [keyPath length] == 0 || [change count] == 0) {
        return;
    }

    if ([change valueForKey:NSKeyValueChangeNewKey] == nil) {
        return;
    }

    if ([keyPath isEqualToString:businessStatus]) {
        if (self.originalStatus != [[change valueForKey:NSKeyValueChangeNewKey] integerValue]) {
            self.originalStatus = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
            self.status = self.originalStatus;
            [self.tableView reloadData];
        }
    }
}

#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([indexPath section] == 0) {
        switch ([indexPath row]) {
            case 0:
                self.status = Online;
                break;
            case 1:
                self.status = Away;
                break;
            default:
                self.status = Offline;
                break;
        }

        [tableView reloadData];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 0) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - UITableViewDataSource Methods -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.status == self.originalStatus) {
        return 1;
    } else {
        return 2;
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.accessoryType = UITableViewCellAccessoryNone;

    if ([indexPath section] == 0) {
        switch ([indexPath row]) {
            case 0:
                if (self.status == Online) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                break;
            case 1:
                if (self.status == Away) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                break;
            default:
                if (self.status == Offline) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
                break;
        }
    }
}

#pragma mark - Action Methods -

- (IBAction)changeButtonPressed:(UIButton *)sender {
    [AppJobs addStatusChangeJob:self.status oldStatus:self.originalStatus];
    self.originalStatus = self.status;
    [self.tableView reloadData];
}

@end
