//
//  AccountSettingsViewController.m
//  Conversa
//
//  Created by Edgar Gomez on 12/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "AccountSettingsViewController.h"

#import "Account.h"
#import "Customer.h"
#import "Constants.h"
#import "YapContact.h"
#import "SettingsKeys.h"
#import "MBProgressHUD.h"
#import "DatabaseManager.h"
#import "NSFileManager+Conversa.h"
#import "DetailAccountViewController.h"
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>

@interface AccountSettingsViewController ()

@property (weak, nonatomic) IBOutlet PFImageView *imageUser;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UILabel *displayNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *conversaIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UISwitch *redirectToConversaSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *sendReadSwitch;
@property (weak, nonatomic) IBOutlet UILabel *blockedContactsLabel;

@property (nonatomic, assign) BOOL reload;

@end

@implementation AccountSettingsViewController

#pragma mark - Lifecycle Methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Hide keyboard when pressed outside TextField
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = FALSE;
    [self.tableView addGestureRecognizer:tap];
    tap.delegate = self;
    
    // Imagen redonda
    self.imageUser.layer.cornerRadius = self.imageUser.frame.size.width / 2;
    self.imageUser.clipsToBounds = YES;
    // Agregar borde
    self.imageUser.layer.borderWidth = 3.0f;
    self.imageUser.layer.borderColor = [UIColor whiteColor].CGColor;
    // Datos iniciales
    self.emailTextField.text = [Account currentUser].email;
    self.usernameTextField.text = [Account currentUser].username;
    //self.displayNameTextField.text = [Account currentUser].displayName;
    self.conversaIdTextField.text = [Account currentUser].username;
    self.redirectToConversaSwitch.on = [SettingsKeys getSendToConversaSetting];
    self.sendReadSwitch.on = [SettingsKeys getSendReadSetting];
    // Delegate
    self.emailTextField.delegate = self;
    self.usernameTextField.delegate = self;
    self.passwordTextField.delegate = self;
    
    UIImage *avatar = [[NSFileManager defaultManager] loadImageFromCache:kAccountAvatarName];
    if (avatar) {
        self.imageUser.image = avatar;
    } else {
        self.imageUser.image = [UIImage imageNamed:@"person"];
        //self.imageUser.file  = [Account currentUser].avatar;
        [self.imageUser loadInBackground];
    }
    
    self.blockedContactsLabel.text = @"Cargando";
    
    self.reload = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveNotification:)
                                                 name:BLOCK_NOTIFICATION_NAME
                                               object:nil];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.reload) {
        self.reload = NO;
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:2]]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BLOCK_NOTIFICATION_NAME object:nil];
}

- (void)dismissKeyboard {
    self.passwordTextField.text = @"";
    [self.view endEditing:YES];
}

- (void) receiveNotification:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:BLOCK_NOTIFICATION_NAME]) {
        self.reload = YES;
    }
}

#pragma mark - UITextFieldDelegate Methods -

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    if (textField == self.passwordTextField) {
        UIAlertController * view=   [UIAlertController
                                     alertControllerWithTitle:nil
                                     message:@"¿Seguro que deseas cambiar tu contraseña?"
                                     preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction* change = [UIAlertAction
                                 actionWithTitle:@"Cambiar"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action) {
                                     Account *user = [Account currentUser];
                                     user.password = self.passwordTextField.text;
                                     
                                     MBProgressHUD *hudError = [[MBProgressHUD alloc] initWithView:self.view];
                                     hudError.mode = MBProgressHUDModeText;
                                     [self.view addSubview:hudError];
                                     
                                     [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                                         if (succeeded && !error) {
                                             hudError.labelText = @"Contraseña cambiada";
                                             [hudError show:YES];
                                             [hudError hide:YES afterDelay:1.7];
                                         } else {
                                             hudError.labelText = @"Contraseña no se ha cambiado";
                                             [hudError show:YES];
                                             [hudError hide:YES afterDelay:1.7];
                                         }
                                         self.passwordTextField.text = @"";
                                     }];
                                 }];
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:@"Cancelar"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action) {
                                     self.passwordTextField.text = @"";
                                     [view dismissViewControllerAnimated:YES completion:nil];
                                 }];
        
        [view addAction:change];
        [view addAction:cancel];
        [self presentViewController:view animated:YES completion:nil];
    }
    
    return YES;
}

#pragma mark - UITableViewDelegate Methods -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([indexPath section] == 4) {
        [self showLogout];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([indexPath section] == 2) {
        if ([indexPath row] == 1) {
            __block NSUInteger count = 0;
            [[DatabaseManager sharedInstance].newConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                [transaction enumerateRowsInCollection:[YapContact collection] usingBlock:^(NSString * _Nonnull key, id  _Nonnull object, id  _Nullable metadata, BOOL * _Nonnull stop) {
                    if (((YapContact*)object).blocked) {
                        count++;
                    }
                }];
            } completionBlock:^{
                if (count == 0) {
                    self.blockedContactsLabel.text = @"Ninguno";
                } else if (count == 1) {
                    self.blockedContactsLabel.text = @"1 contacto";
                } else {
                    self.blockedContactsLabel.text = [[NSString stringWithFormat:@"%lu", (unsigned long)count] stringByAppendingString:@" contactos"];
                }
            }];
        }
    }
    
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark - Navigation Method -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"DetailAccountSegue"]) {
        DetailAccountViewController *controller = [segue destinationViewController];
        controller.avatar = self.imageUser.image;
    }
}

#pragma mark - Action Methods -

- (void)showLogout {
    UIAlertController * view =   [UIAlertController
                                  alertControllerWithTitle:nil
                                  message:nil
                                  preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* logout = [UIAlertAction
                             actionWithTitle:@"Cerrar sesión"
                             style:UIAlertActionStyleDestructive
                             handler:^(UIAlertAction * action) {
                                 [Account logOut];
                                 [view dismissViewControllerAnimated:YES completion:nil];
                                 UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                 UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
                                 [self presentViewController:viewController animated:YES completion:nil];
                             }];
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:@"Cancelar"
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action) {
                                 [view dismissViewControllerAnimated:YES completion:nil];
                             }];
    
    
    [view addAction:logout];
    [view addAction:cancel];
    [self presentViewController:view animated:YES completion:nil];
}

- (IBAction)setRedirectToConversaAction:(UISwitch *)sender {
    if (sender.on) {
        [SettingsKeys setSendToConversaSetting:YES];
    } else {
        [SettingsKeys setSendToConversaSetting:NO];
    }
}

- (IBAction)sendReadAction:(UISwitch *)sender {
    if (sender.on) {
        [SettingsKeys setSendReadSetting:YES];
    } else {
        [SettingsKeys setSendReadSetting:NO];
    }
}

@end
