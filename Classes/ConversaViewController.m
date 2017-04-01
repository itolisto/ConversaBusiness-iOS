//
//  ConversaViewController.m
//  ConversaManager
//
//  Created by Edgar Gomez on 12/27/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "ConversaViewController.h"

#import "Colors.h"
#import "SettingsKeys.h"
#import "UIStateButton.h"
#import "MBProgressHUD.h"

@interface ConversaViewController ()
@property (weak, nonatomic) IBOutlet UILabel *conversaId;
@property (weak, nonatomic) IBOutlet UIStateButton *shareButton;

@end

@implementation ConversaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];

    self.conversaId.text = [@"conversa.link/" stringByAppendingString:([SettingsKeys getConversaId]) ? [SettingsKeys getConversaId] : @""];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(copyLink)];
    tap.numberOfTapsRequired = 1;
    [self.conversaId addGestureRecognizer:tap];
    self.conversaId.userInteractionEnabled = YES;

    tap.delegate = self;

    // Add border to Button
    [self.shareButton setBackgroundColor:[Colors secondaryPurple] forState:UIControlStateNormal];
    [self.shareButton setTitleColor:[Colors white] forState:UIControlStateNormal];
    [self.shareButton setBackgroundColor:[UIColor clearColor] forState:UIControlStateHighlighted];
    [self.shareButton setTitleColor:[Colors secondaryPurple] forState:UIControlStateHighlighted];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)copyLink {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = [@"https://conversa.link/" stringByAppendingString:([SettingsKeys getConversaId]) ? [SettingsKeys getConversaId] : @""];

    MBProgressHUD *hudError = [[MBProgressHUD alloc] initWithView:self.view];
    hudError.mode = MBProgressHUDModeText;
    [self.view addSubview:hudError];

    hudError.label.text = NSLocalizedString(@"conversalink_share_copy", nil);

    [hudError showAnimated:YES];
    [hudError hideAnimated:YES afterDelay:1.7];
}

- (IBAction)shareButtonPressed:(UIStateButton *)sender {
    NSString *link = [@"https://conversa.link/" stringByAppendingString:([SettingsKeys getConversaId]) ? [SettingsKeys getConversaId] : @""];

    NSString *textToShare = [NSString stringWithFormat:NSLocalizedString(@"conversalink_share_text", nil),
                             link];

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

@end
