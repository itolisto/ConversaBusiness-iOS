//
//  ParseValidation.m
//  Conversa
//
//  Created by Edgar Gomez on 11/12/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

#import "ParseValidation.h"
#import "Account.h"

@implementation ParseValidation

+ (BOOL)validateError:(NSError *)error {
    switch (error.code) {
        case kPFErrorInvalidSessionToken: {
            return YES;
        }
        default:
            return NO;
    }
}

+ (void)_handleInvalidSessionTokenError:(UIViewController *)fromController {
    UIAlertController * view = [UIAlertController
                                alertControllerWithTitle:nil
                                message:NSLocalizedString(@"token_session_error", nil)
                                preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* ok = [UIAlertAction
                         actionWithTitle:@"Ok"
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction * action) {
                             [Account logOut];
                             [view dismissViewControllerAnimated:YES completion:nil];
                             UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                             UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
                             [fromController presentViewController:viewController animated:YES completion:nil];
                         }];
    [view addAction:ok];
    [fromController presentViewController:view animated:YES completion:nil];
}

@end
