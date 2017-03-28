//
//  AppDelegate.m
//  Conversa
//
//  Created by Edgar Gomez on 12/10/15.
//  Copyright © 2015 Conversa. All rights reserved.
//

#import "AppDelegate.h"

#import "Log.h"
#import "Account.h"
#import "AppJobs.h"
#import "Customer.h"
#import "Constants.h"
#import "Appirater.h"
#import "YapContact.h"
#import "YapMessage.h"
#import "SettingsKeys.h"
#import "ParseValidation.h"
#import "DatabaseManager.h"
#import "OneSignalService.h"
#import "CustomAblyRealtime.h"
#import "NSFileManager+Conversa.h"
#import <AFNetworking/AFNetworking.h>
@import Parse;
@import Fabric;
@import Buglife;
@import GoogleMaps;
@import Crashlytics;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //[Appirater setAppId:@"464200063"];
    
    // Set Google Maps
    [GMSServices provideAPIKey:@"AIzaSyDnp-8x1YyMNjhmi4R7O3foOcdkfMa4cNs"];
    
    // Set Fabric
    [Fabric with:@[[Answers class], [Crashlytics class]]];

    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode console
    [DDLog addLogger:[DDASLLogger sharedInstance]]; // ASL = Apple System Logs
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init]; // File Logger
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:fileLogger];
    
    // Register subclassing for using as Parse objects
    [Account registerSubclass];
    [Customer registerSubclass];
    
    // Initialize Parse.
    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
        configuration.applicationId = @"szLKzjFz66asK9SngeFKnTyN2V596EGNuMTC7YyF4tkFudvY72";
        configuration.clientKey = @"CMTFwQPd2wJFXfEQztpapGHFjP5nLZdtZr7gsHKxuFhA9waMgw1";
        configuration.server = @"http://ec2-52-71-125-28.compute-1.amazonaws.com:1337/parse";
        // To work with localhost
//        configuration.applicationId = @"b15c83";
//        configuration.server = @"http://localhost:1337/parse";
    }]];
    
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"Home directory: %@",NSHomeDirectory());
#endif
    
    if (![DatabaseManager existsYapDatabase]) {
        /*
         * First Launch
         * Create password and save to keychain
         */
        NSString *newPassword = @"123456789";//[PasswordGenerator passwordWithLength:DefaultPasswordLength];
        NSError *error = nil;
        [[DatabaseManager sharedInstance] setDatabasePassphrase:newPassword remember:YES error:&error];
        
        if (error) {
            DDLogError(@"Password Error: %@",error);
        }
        
        // Default settings
        [SettingsKeys setTutorialShownSetting:NO];
    }
    
    [[DatabaseManager sharedInstance] setupDatabaseWithName:kYapDatabaseName];
    
    // Define controller to take action
    UIViewController *rootViewController = nil;
    rootViewController = [self defaultNavigationController];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = rootViewController;
    // Make the receiver the main window and displays it in front of other windows
    [self.window makeKeyAndVisible];
    // The number to display as the app’s icon badge.
    application.applicationIconBadgeNumber = 0;
    
    [[Buglife sharedBuglife] startWithAPIKey:@"16odhSYLVoCFcrgZh3q8dwtt"];
    [Buglife sharedBuglife].invocationOptions = LIFEInvocationOptionsShake;
    
    // Set Appirater settings
    [Appirater setOpenInAppStore:NO];
    [Appirater appLaunched:YES];
    
    [[OneSignalService sharedInstance] launchWithOptions:launchOptions];

    return YES;
}

- (UIViewController*)defaultNavigationController
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    Account *account = [Account currentUser];
    BOOL hasAccount = NO;
    
    if (account) {
        hasAccount = YES;
        [SettingsKeys setNotificationsCheck:NO];
    }
    
    /**
     * Proceso para nombrar controladores en Storyboard
     * 1. Seleccionar Storyboard
     * 2. Seleccionar Scene deseada
     * 3. Abrir Identity inspector
     * 4. Propiedad Storyboard ID se escribe nombre
     */
    if (hasAccount) {
        return [storyboard instantiateViewControllerWithIdentifier:@"HomeView"];
    } else {
        if([SettingsKeys getTutorialShownSetting]) {
            return [storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
        } else {
            return [storyboard instantiateViewControllerWithIdentifier:@"Tutorial"];
        }
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification{ }

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[EDQueue sharedInstance] stop];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [[EDQueue sharedInstance] setDelegate:self];
    [[EDQueue sharedInstance] start];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {

}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {

}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"%s with error: %@", __PRETTY_FUNCTION__, error);
}

#pragma mark - EDQueueDelegate method -

- (UIViewController *)topViewController {
    return [self topViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

- (UIViewController *)topViewController:(UIViewController *)rootViewController
{
    if (rootViewController.presentedViewController == nil) {
        return rootViewController;
    }

    if ([rootViewController.presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController.presentedViewController;
        UIViewController *lastViewController = [[navigationController viewControllers] lastObject];
        return [self topViewController:lastViewController];
    }

    UIViewController *presentedViewController = (UIViewController *)rootViewController.presentedViewController;
    return [self topViewController:presentedViewController];
}

- (void)queue:(EDQueue *)queue processJob:(NSDictionary *)job completion:(void (^)(EDQueueResult))block
{
    @try {
        if ([[job objectForKey:@"task"] isEqualToString:@"businessDataJob"]) {
            NSError *error;
            NSString *jsonData = [PFCloud callFunction:@"getBusinessId" withParameters:@{} error:&error];

            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([ParseValidation validateError:error]) {
                        [ParseValidation _handleInvalidSessionTokenError:[self topViewController]];
                    }
                });
                block(EDQueueResultCritical);
            } else {
                id object = [NSJSONSerialization JSONObjectWithData:[jsonData dataUsingEncoding:NSUTF8StringEncoding]
                                                            options:0
                                                              error:&error];
                if (error) {
                    block(EDQueueResultCritical);
                } else {
                    if ([object isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *results = object;

                        if ([results objectForKey:@"ob"] && [results objectForKey:@"ob"] != [NSNull null]) {
                            [SettingsKeys setBusinessId:[results objectForKey:@"ob"]];
                        }

                        if ([results objectForKey:@"dn"] && [results objectForKey:@"dn"] != [NSNull null]) {
                            [SettingsKeys setDisplayName:[results objectForKey:@"dn"]];
                        }

                        if ([results objectForKey:@"pp"] && [results objectForKey:@"pp"] != [NSNull null]) {
                            [SettingsKeys setPaidPlan:[results objectForKey:@"pp"]];
                        }

                        if ([results objectForKey:@"ct"] && [results objectForKey:@"ct"] != [NSNull null]) {
                            [SettingsKeys setCountry:[results objectForKey:@"ct"]];
                        }

                        if ([results objectForKey:@"id"] && [results objectForKey:@"id"] != [NSNull null]) {
                            [SettingsKeys setConversaId:[results objectForKey:@"id"]];
                        }

                        if ([results objectForKey:@"ab"] && [results objectForKey:@"ab"] != [NSNull null]) {
                            [SettingsKeys setAbout:[results objectForKey:@"ab"]];
                        }

                        if ([results objectForKey:@"vd"] && [results objectForKey:@"vd"] != [NSNull null]) {
                            [SettingsKeys setVerified:[[results objectForKey:@"vd"] boolValue]];
                        }

                        if ([results objectForKey:@"rc"] && [results objectForKey:@"rc"] != [NSNull null]) {
                            [SettingsKeys setRedirect:[[results objectForKey:@"rc"] boolValue]];
                        }

                        if ([results objectForKey:@"av"] && [results objectForKey:@"av"] != [NSNull null]) {
                            [SettingsKeys setAvatarUrl:[results objectForKey:@"av"]];
                        }

                        if ([results objectForKey:@"st"] && [results objectForKey:@"st"] != [NSNull null]) {
                            NSInteger status = [[results objectForKey:@"st"] integerValue];
                            if (status == -1) {
                                [SettingsKeys setRedirect:YES];
                            }
                            [SettingsKeys setStatus:status];
                        }

                        block(EDQueueResultSuccess);
                    } else {
                        block(EDQueueResultCritical);
                    }
                }
            }
        } else if ([[job objectForKey:@"task"] isEqualToString:@"downloadFileJob"]) {
            NSDictionary *data = [job objectForKey:@"data"];

            NSString *messageId = [data objectForKey:@"messageId"];
            NSString *url = [data objectForKey:@"url"];
            NSInteger messageType = [[data objectForKey:@"type"] integerValue];

            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
            NSURL *URL = [NSURL URLWithString:url];
            NSURLRequest *request = [NSURLRequest requestWithURL:URL];

            NSURLSessionDownloadTask *downloadTask =
            [manager downloadTaskWithRequest:request
                                    progress:nil
                                 destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response)
             {
                 NSMutableString *savePath = [[NSMutableString alloc] initWithFormat:@"%@", [[NSFileManager defaultManager] applicationLibraryDirectory].path];

                 switch (messageType) {
                     case kMessageTypeImage: {
                         [savePath appendString:kMessageMediaImageLocation];
                         // Create if not already created
                         [[NSFileManager defaultManager] createDirectory:[savePath copy]];
                         // Continue with filename
                         [savePath appendString:@"/"];
                         // Add requested save path
                         [savePath appendString:messageId];
                         [savePath appendString:@".jpg"];
                         break;
                     }
                     case kMessageTypeAudio: {
                         [savePath appendString:kMessageMediaAudioLocation];
                         // Create if not already created
                         [[NSFileManager defaultManager] createDirectory:[savePath copy]];
                         // Continue with filename
                         [savePath appendString:@"/"];
                         // Add requested save path
                         [savePath appendString:messageId];
                         [savePath appendString:@".mp3"];
                         break;
                     }
                     default: {
                         [savePath appendString:kMessageMediaVideoLocation];
                         // Create if not already created
                         [[NSFileManager defaultManager] createDirectory:[savePath copy]];
                         // Continue with filename
                         [savePath appendString:@"/"];
                         // Add requested save path
                         [savePath appendString:messageId];
                         [savePath appendString:@".mp4"];
                         break;
                     }
                 }

                 return [[NSURL alloc] initFileURLWithPath:savePath];
             }
                           completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error)
             {
                 DDLogInfo(@"downloadFileJob downloaded to: %@", filePath);
                 YapDatabaseConnection *connection = [DatabaseManager sharedInstance].newConnection;
                 __block YapMessage *message = nil;

                 [connection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                     message = [YapMessage fetchObjectWithUniqueID:messageId transaction:transaction];
                 }];

                 if (message == nil) {
                     // Delete file if message not exists
                     [[NSFileManager defaultManager] deleteDataInDirectory:[filePath absoluteString]
                                                                     error:nil];
                 } else {
                     if (error) {
                         DDLogError(@"downloadFileJob error: %@", error);
                         message.delivered = statusParseError;
                         [[NSFileManager defaultManager] deleteDataInDirectory:[filePath absoluteString]
                                                                         error:nil];
                     } else {
                         message.delivered = statusReceived;
                         switch (messageType) {
                             case kMessageTypeImage: {
                                 message.filename = [messageId stringByAppendingString:@".jpg"];
                                 break;
                             }
                             case kMessageTypeAudio: {
                                 message.filename = [messageId stringByAppendingString:@".mp3"];
                                 break;
                             }
                             default: {
                                 message.filename = [messageId stringByAppendingString:@".mp4"];
                                 break;
                             }
                         }
                     }

                     [connection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction)
                      {
                          [message saveWithTransaction:transaction];
                          // Make a YapDatabaseModifiedNotification to update
                          NSDictionary *transactionExtendedInfo = @{YapDatabaseModifiedNotificationUpdate: @TRUE};
                          transaction.yapDatabaseModifiedNotificationCustomObject = transactionExtendedInfo;
                      }];
                 }

                 block(EDQueueResultSuccess);
             }];

            [downloadTask resume];
        } else if ([[job objectForKey:@"task"] isEqualToString:@"downloadAvatarJob"]) {
            NSDictionary *data = [job objectForKey:@"data"];
            NSString *url = [data objectForKey:@"url"];

            NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
            AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
            NSURL *URL = [NSURL URLWithString:url];
            NSURLRequest *request = [NSURLRequest requestWithURL:URL];

            NSURLSessionDownloadTask *downloadTask =
            [manager downloadTaskWithRequest:request
                                    progress:nil
                                 destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response)
             {
                 NSMutableString *savePath = [[NSMutableString alloc] initWithFormat:@"%@", [[NSFileManager defaultManager] applicationLibraryDirectory].path];
                 [savePath appendString:kMessageMediaAvatarLocation];
                 // Create if not already created
                 [[NSFileManager defaultManager] createDirectory:[savePath copy]];
                 // Continue with filename
                 [savePath appendString:@"/"];
                 // Add requested save path
                 [savePath appendString:kAccountAvatarName];

                 return [[NSURL alloc] initFileURLWithPath:savePath];
             }
                           completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error)
             {
                 DDLogInfo(@"downloadAvatarJob downloaded to: %@", filePath);
                 if (error) {
                     DDLogError(@"downloadAvatarJob error: %@", error);
                     [[NSFileManager defaultManager] deleteDataInDirectory:[filePath absoluteString]
                                                                     error:nil];
                     block(EDQueueResultCritical);
                 } else {
                     [SettingsKeys setAvatarUrl:@""];
                     block(EDQueueResultSuccess);
                 }
             }];

            [downloadTask resume];
        } else if ([[job objectForKey:@"task"] isEqualToString:@"statusChangeJob"]) {
            NSDictionary *data = [job objectForKey:@"data"];
            NSInteger status = [[data objectForKey:@"status"] integerValue];

            NSError *error;
            [PFCloud callFunction:@"updateBusinessStatus"
                   withParameters:@{@"status": @(status), @"businessId": [SettingsKeys getBusinessId]}
                            error:&error];

            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([ParseValidation validateError:error]) {
                        [ParseValidation _handleInvalidSessionTokenError:[self topViewController]];
                    }
                });
                block(EDQueueResultCritical);
            } else {
                [SettingsKeys setStatus:status];
                block(EDQueueResultSuccess);
            }
        } else if ([[job objectForKey:@"task"] isEqualToString:@"redirectToConversaJob"]) {
            NSDictionary *data = [job objectForKey:@"data"];
            BOOL redirect = [[data objectForKey:@"redirect"] boolValue];

            NSError *error;
            [PFCloud callFunction:@"updateBusinessRedirect"
                   withParameters:@{@"redirect": @(redirect), @"businessId": [SettingsKeys getBusinessId]}
                            error:&error];

            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([ParseValidation validateError:error]) {
                        [ParseValidation _handleInvalidSessionTokenError:[self topViewController]];
                    }
                });
                block(EDQueueResultCritical);
            } else {
                [SettingsKeys setRedirect:redirect];
                if (redirect) {
                    [SettingsKeys setStatus:Conversa];
                } else {
                    [SettingsKeys setStatus:Online];
                }
                block(EDQueueResultSuccess);
            }
        } else {
            block(EDQueueResultCritical);
        }
    } @catch (NSException *exception) {
        block(EDQueueResultCritical);
    } @catch (id exception) {
        block(EDQueueResultCritical);
    }
}

@end
