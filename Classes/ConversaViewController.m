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

@interface ConversaViewController ()
@property (weak, nonatomic) IBOutlet UILabel *conversaId;
@property (weak, nonatomic) IBOutlet UIStateButton *shareButton;

@end

@implementation ConversaViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];

    self.conversaId.text = [SettingsKeys getConversaId];

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

- (IBAction)shareButtonPressed:(UIStateButton *)sender {

}

@end
