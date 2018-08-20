//
//  AboutViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 2/28/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "AboutViewController.h"

#import "Account.h"
#import "YapContact.h"
#import "MBProgressHUD.h"
#import "DatabaseManager.h"
#import "ParseValidation.h"
#import "ConversationViewController.h"

@interface AboutViewController ()

@property(nonatomic, strong) MBProgressHUD *hud;

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    // Remove extra lines
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:v];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)viewWillDisappear:(BOOL)animated {
    if (self.hud) {
        [self.hud hideAnimated:YES];
    }
    [super viewWillDisappear:animated];
}

#pragma mark - SFSafariViewControllerDelegate Methods -

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        // Support
        [self callForId:@"1"];
    } else {
        // Terms & Privacy
        SFSafariViewController *svc = [[SFSafariViewController alloc]initWithURL:[NSURL URLWithString:@"http://manager.conversachat.com/terms"] entersReaderIfAvailable:NO];
        svc.delegate = self;
        [self presentViewController:svc animated:YES completion:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)callForId:(NSString*)purpose {
    self.hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    self.hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
    self.hud.label.text = NSLocalizedString(@"sett_help_dialog_support_message", nil);
    [self.hud showAnimated:YES];

    __weak typeof(self) wself = self;
    // TODO: Replace with networking layer
//    [PFCloud callFunctionInBackground:@"getConversaAccountId"
//                       withParameters:@{@"purpose": @([purpose intValue])}
//                                block:^(NSString *  _Nullable objectId, NSError * _Nullable error)
//     {
//         typeof(self)sSelf = wself;
//
//         if (sSelf) {
//             if (error) {
//                 if ([ParseValidation validateError:error]) {
//                     [ParseValidation _handleInvalidSessionTokenError:[sSelf topViewController]];
//                 } else {
//                     [sSelf.hud hideAnimated:YES];
//                     [sSelf showError];
//                 }
//             } else {
//                 __block YapContact *contact;
//                 [[DatabaseManager sharedInstance].newConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
//                     [YapContact fetchObjectWithUniqueID:objectId transaction:transaction];
//                 }];
//
//                 if (contact) {
//                     // Go to profile
//                     [sSelf goToConversationFor:contact shouldAdd:NO];
//                 } else {
//                     [sSelf callForAccount:objectId];
//                 }
//             }
//         }
//     }];
}

- (void)callForAccount:(NSString*)accountId {
    __weak typeof(self) wself = self;
    // TODO: Replace with networking layer
//    [PFCloud callFunctionInBackground:@"getConversaAccount"
//                       withParameters:@{@"accountId": accountId}
//                                block:^(NSString *  _Nullable jsonData, NSError * _Nullable error)
//     {
//         typeof(self)sSelf = wself;
//
//         if (sSelf) {
//             [sSelf.hud hideAnimated:YES];
//
//             if (error) {
//                 if ([ParseValidation validateError:error]) {
//                     [ParseValidation _handleInvalidSessionTokenError:[sSelf topViewController]];
//                 } else {
//                     [sSelf showError];
//                 }
//             } else {
//                 NSDictionary *results = [NSJSONSerialization JSONObjectWithData:[jsonData dataUsingEncoding:NSUTF8StringEncoding]
//                                                                         options:0
//                                                                           error:&error];
//
//                 YapContact *newBuddy = [[YapContact alloc] initWithUniqueId:[results objectForKey:@"oj"]];
//                 newBuddy.accountUniqueId = [Account currentUser].objectId;
//                 newBuddy.displayName = [results objectForKey:@"dn"];
//                 newBuddy.composingMessageString = @"";
//                 newBuddy.blocked = NO;
//                 newBuddy.mute = NO;
//                 // Go to profile
//                 [sSelf goToConversationFor:newBuddy shouldAdd:YES];
//             }
//         }
//     }];
}

- (void)goToConversationFor:(YapContact*)contact shouldAdd:(BOOL)add {
    if (self.isViewLoaded && self.view.window) {
        // Get reference to the destination view controller
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        ConversationViewController *destinationViewController = [storyboard instantiateViewControllerWithIdentifier:@"conversationViewController"];

        destinationViewController.position = 0;
        [destinationViewController initWithBuddy:contact];
        // Override checkIfAlreadyAdded flag
        destinationViewController.checkIfAlreadyAdded = add;

        UIViewController *controller = [self topViewController];

        if (controller) {
            if ([controller isKindOfClass:[UITabBarController class]]) {
                UITabBarController *tbcontroller = (UITabBarController*)controller;
                UIViewController *scontroller = [tbcontroller selectedViewController];

                if ([scontroller isKindOfClass:[UINavigationController class]]) {
                    UINavigationController *navcontroller = (UINavigationController*)scontroller;

                    if (navcontroller.isNavigationBarHidden) {
                        navcontroller.navigationBarHidden = NO;
                    }

                    [navcontroller pushViewController:destinationViewController
                                             animated:YES];
                } else {
                    // scontroller is a uiviewcontroller
                    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:scontroller];

                    [navController pushViewController:destinationViewController
                                             animated:YES];
                }
            } else if ([controller isKindOfClass:[UINavigationController class]]) {
                UINavigationController *navcontroller = (UINavigationController*)controller;
                [navcontroller presentViewController:destinationViewController
                                            animated:YES
                                          completion:nil];
            } else {
                if (controller.navigationController) {
                    [controller.navigationController pushViewController:destinationViewController
                                                               animated:YES];
                } else {
                    // Create UINavigationController if not exists
                    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];

                    [navController pushViewController:destinationViewController
                                             animated:YES];
                }
            }
        }
    }
}

- (void)showError {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.mode = MBProgressHUDModeText;
    //hud.square = YES;
    hud.detailsLabel.text = NSLocalizedString(@"sett_help_dialog_message_error", nil);
    [hud hideAnimated:YES afterDelay:2.f];
}

@end
